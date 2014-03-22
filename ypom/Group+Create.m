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

- (void)addUser:(User *)user
{
    for (UserGroup *userGroup in self.hasUsers) {
        if (userGroup.user == user) {
            return;
        }
    }
    UserGroup *userGroup = [NSEntityDescription insertNewObjectForEntityForName:@"UserGroup" inManagedObjectContext:self.managedObjectContext];
    userGroup.group = self;
    userGroup.user = user;
}

- (void)removeUser:(User *)user
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"UserGroup"];
    request.predicate = [NSPredicate predicateWithFormat:@"group = %@ AND user = %@", self, user];
    
    NSError *error = nil;
        NSArray *matches = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if (!matches) {
        // handle error
    } else {
        for (NSManagedObject *object in matches) {
            [self.managedObjectContext deleteObject:object];
        }
    }
}

- (NSString *)displayName
{
    return self.name ? self.name : [NSString stringWithFormat:@"#%@", self.identifier];
}

@end
