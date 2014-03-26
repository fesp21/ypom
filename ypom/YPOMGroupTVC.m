//
//  YPOMGroupTVC.m
//  ypom
//
//  Created by Christoph Krey on 21.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOMGroupTVC.h"
#import "YPOMAppDelegate.h"

@interface YPOMGroupTVC ()
@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *number;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *inviteButton;

@end

@implementation YPOMGroupTVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = [NSString stringWithFormat:@"👥 %@", [self.group displayName]];
    self.name.text = self.group.name;
    self.number.text = [NSString stringWithFormat:@"%lu", (unsigned long)[self.group.hasUsers count]];
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    if (self.group.belongsTo == delegate.myself.myUser) {
        self.inviteButton.enabled = TRUE;
        self.name.enabled = TRUE;
    } else {
        self.inviteButton.enabled = FALSE;
        self.name.enabled = FALSE;
    }
    
    self.tableView.backgroundColor = delegate.theme.backgroundColor;
}

- (IBAction)nameChanged:(UITextField *)sender {
    self.group.name = sender.text;
    self.title = [NSString stringWithFormat:@"👥 %@", [self.group displayName]];

    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate saveContext];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"setGroupForMembers:"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setGroup:)]) {
            [segue.destinationViewController performSelector:@selector(setGroup:)
                                                  withObject:self.group];
        }
    }
}


@end
