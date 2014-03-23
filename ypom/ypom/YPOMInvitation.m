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
    self.alert = [[UIAlertView alloc] initWithTitle:@"YPOM Group Invitation"
                                            message:[NSString stringWithFormat:@"👤%@ 👥%@",
                                                     [self.user displayName],
                                                     self.group[@"name"] ? self.group[@"name"] : self.group[@"id"]
                                                     ]
                                           delegate:self
                                  cancelButtonTitle:@"Ignore"
                                  otherButtonTitles:@"Accept", nil];
    [self.alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex) {
        NSString *groupIdentifier = self.group[@"id"];
        
        Group *group = [Group groupWithIdentifier:groupIdentifier
                                        belongsTo:self.user
                           inManagedObjectContext:self.user.managedObjectContext];
        group.name = self.group[@"name"];
        [group join];
    }
}


@end
