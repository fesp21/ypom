//
//  Group+Create.m
//  ypom
//
//  Created by Christoph Krey on 21.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "Group+Create.h"
#import "OSodiumBox.h"
#import <sodium.h>
#import "base32.h"
#import "UserGroup.h"
#import "User+Create.h"
#import "YPOMAppDelegate.h"

#define IDENTIFIER_LEN 5

@implementation Group (Create)

+ (Group *)newGroupInManageObjectContext:(NSManagedObjectContext *)context
                               belongsTo:(User *)belongsTo
{
    OSodiumBox *box = [[OSodiumBox alloc] init];
    [box createKeyPair];
    
    unsigned char h[crypto_hash_sha256_BYTES];
    crypto_hash_sha256(h, box.pubkey.bytes, box.pubkey.length);
    
    unsigned char pk32[BASE32_LEN(IDENTIFIER_LEN) + 1];
    base32_encode(h, BASE32_LEN(IDENTIFIER_LEN), pk32);
    pk32[BASE32_LEN(IDENTIFIER_LEN)] = 0;
    
    NSString *identifier = [NSString stringWithUTF8String:(char *)pk32];
    
    Group *group = [Group groupWithIdentifier:identifier
                                    belongsTo:belongsTo
                       inManagedObjectContext:context];
    return group;
}

+ (Group *)groupWithIdentifier:(NSString *)identifier
                     belongsTo:(User *)belongsTo
        inManagedObjectContext:(NSManagedObjectContext *)context
{
    Group *group = [Group existsGroupWithIdentifier:identifier
                             inManagedObjectContext:context];
    
    if (!group) {
        
        group = [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:context];
        
        group.identifier = identifier;
        group.isUser = [User userWithIdentifier:identifier inManagedObjectContext:context];
        group.belongsTo = belongsTo;
    }
    
    return group;
}


+ (Group *)existsGroupWithIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)context
{
    Group *group = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Group"];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier = %@", identifier];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches) {
        // handle error
    } else {
        if ([matches count]) {
            group = [matches lastObject];
        }
    }
    
    return group;
}

- (BOOL)addUser:(User *)user
{
    for (UserGroup *userGroup in self.hasUsers) {
        if (userGroup.user == user) {
            return FALSE;
        }
    }
    UserGroup *userGroup = [NSEntityDescription insertNewObjectForEntityForName:@"UserGroup" inManagedObjectContext:self.managedObjectContext];
    userGroup.group = self;
    userGroup.user = user;
    userGroup.group.identifier = userGroup.group.identifier; // touch group
    userGroup.group.belongsTo.identifier = userGroup.group.belongsTo.identifier; // touch user
    
    return TRUE;
}

- (BOOL)removeUser:(User *)user
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"UserGroup"];
    request.predicate = [NSPredicate predicateWithFormat:@"group = %@ AND user = %@", self, user];
    
    NSError *error = nil;
        NSArray *matches = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if (!matches) {
        // handle error
    } else {
        if ([matches count]) {
            for (UserGroup *userGroup in matches) {
                [self.managedObjectContext deleteObject:userGroup];
            }
            self.identifier = self.identifier; // touch
            
            return TRUE;
        }
    }
    return FALSE;
}

- (NSString *)displayName
{
    return self.name ? self.name : [NSString stringWithFormat:@"#%@", self.identifier];
}

- (void)tell
{
    NSError *error;
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    jsonObject[@"_type"] = @"tell";
    jsonObject[@"timestamp"] = [NSString stringWithFormat:@"%.3f",
                                [[NSDate date] timeIntervalSince1970]];
    
    NSMutableArray *members = [[NSMutableArray alloc] init];
    for (UserGroup *userGroup in self.hasUsers) {
        [members addObject:userGroup.user.identifier];
    }
    NSDictionary *groupDictionary = @{
                                      @"id": self.identifier,
                                      @"name": self.name,
                                      @"members":members
                                      };
    jsonObject[@"group"] = groupDictionary;
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                   options:0
                                                     error:&error];
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    for (UserGroup *userGroup in self.hasUsers) {
        [delegate safeSend:data to:userGroup.user];
        [delegate sendPush:userGroup.user];
    }
    [delegate safeSend:data to:self.belongsTo];
    [delegate sendPush:self.belongsTo];

}

- (void)listen:(NSDictionary *)groupDictionary
{
    NSArray *members = groupDictionary[@"members"];
    NSMutableArray *usersLeft = [[NSMutableArray alloc] init];

    for (UserGroup *userGroup in self.hasUsers) {
        NSString *identifier = nil;
        for (identifier in members) {
            if ([identifier isEqualToString:userGroup.user.identifier]) {
                break;
            }
        }
        if (!identifier) {
            [usersLeft addObject:userGroup.user];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"YPOM Group Leave"
                                                            message:[NSString stringWithFormat:@"👤%@ 👥%@",
                                                                     [userGroup.user displayName],
                                                                     [self displayName]
                                                                     ]
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
    
    for (User *user in usersLeft) {
        [self removeUser:user];
    }

    for (NSString *identifier in members) {
        User *user = [User existsUserWithIdentifier:identifier inManagedObjectContext:self.managedObjectContext];
        if (user) {
            if ([self addUser:user]) {
                user.identifier = user.identifier; // touch
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"YPOM Group Join"
                                                                message:[NSString stringWithFormat:@"👤%@ 👥%@",
                                                                         [user displayName],
                                                                         [self displayName]
                                                                         ]
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }
    }
}

- (void)invite:(User *)user
{
    NSError *error;
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    jsonObject[@"_type"] = @"inv";
    jsonObject[@"timestamp"] = [NSString stringWithFormat:@"%.3f",
                                [[NSDate date] timeIntervalSince1970]];
    NSDictionary *group = @{
                            @"id": self.identifier,
                            @"name": self.name,
                            };
    jsonObject[@"group"] = group;
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate safeSend:data to:user];
}

- (void)leave
{
    if (self.belongsTo) {
        NSError *error;
        NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
        jsonObject[@"_type"] = @"leave";
        jsonObject[@"timestamp"] = [NSString stringWithFormat:@"%.3f",
                                    [[NSDate date] timeIntervalSince1970]];
        NSDictionary *groupDictionary = @{
                                          @"id": self.identifier,
                                          };
        jsonObject[@"group"] = groupDictionary;
        
        NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
        
        YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
        [delegate safeSend:data to:self.belongsTo];
        [delegate sendPush:self.belongsTo];
    }
}

- (void)join
{
    if (self.belongsTo) {
        NSError *error;
        NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
        jsonObject[@"_type"] = @"join";
        jsonObject[@"timestamp"] = [NSString stringWithFormat:@"%.3f",
                                    [[NSDate date] timeIntervalSince1970]];
        
        NSDictionary *groupDictionary = @{
                                          @"id": self.identifier,
                                          };
        jsonObject[@"group"] = groupDictionary;
        
        NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
        
        YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
        [delegate safeSend:data to:self.belongsTo];
        [delegate sendPush:self.belongsTo];
    }
}


@end
