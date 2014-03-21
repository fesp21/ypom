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

@end

@implementation YPOMGroupTVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.name.text = self.group.name;
    self.number.text = [NSString stringWithFormat:@"%lu", (unsigned long)[self.group.hasUsers count]];
}


- (IBAction)nameChanged:(UITextField *)sender {
    self.group.name = sender.text;
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate saveContext];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"setGroupForInvite:"] || [segue.identifier isEqualToString:@"setGroupForMembers:"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setGroup:)]) {
            [segue.destinationViewController performSelector:@selector(setGroup:)
                                                  withObject:self.group];
        }
    }
}


@end
