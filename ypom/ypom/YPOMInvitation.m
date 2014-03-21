//
//  YPOMInvitation.m
//  ypom
//
//  Created by Christoph Krey on 21.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOMInvitation.h"
#import "YPOMAppDelegate.h"
#import "Group+Create.h"
#import "User+Create.h"
#import "UserGroup.h"

@interface YPOMInvitation ()
@property (strong, nonatomic) UIAlertView *alert;
@end

@implementation YPOMInvitation

- (void)show
{
    self.alert = [[UIAlertView alloc]
                          initWithTitle:@"YPOM Group Invitation"
                          message:self.group[@"name"]                                                                           delegate:self
                          cancelButtonTitle:@"Ignore"
                          otherButtonTitles:@"Accept", nil];
    [self.alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex) {
        YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
        
        NSString *groupIdentifier = self.group[@"id"];
        
        Group *group = [Group groupWithIdentifier:groupIdentifier
                           inManagedObjectContext:delegate.managedObjectContext];
        group.name = self.group[@"name"];
        [group addUser:delegate.myself.myUser];
        
        NSError *error;
        NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
        jsonObject[@"_type"] = @"join";
        jsonObject[@"timestamp"] = [NSString stringWithFormat:@"%.3f",
                                    [[NSDate date] timeIntervalSince1970]];
        
        NSMutableArray *members = [[NSMutableArray alloc] init];
        for (UserGroup *userGroup in group.hasUsers) {
            [members addObject:userGroup.user.identifier];
        }
        NSDictionary *groupDictionary = @{
                                          @"id": group.identifier,
                                          @"name": group.name,
                                          @"members":members
                                          };
        jsonObject[@"group"] = groupDictionary;
        
        NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                       options:0
                                                         error:&error];
        
        for (NSString *identifier in self.group[@"members"]) {
            User *user = [User existsUserWithIdentifier:identifier
                                 inManagedObjectContext:delegate.managedObjectContext];
            if (user && user != delegate.myself.myUser) {
                [delegate safeSend:data to:user];
                [delegate sendPush:user];
            }
        }
    }
}


@end
