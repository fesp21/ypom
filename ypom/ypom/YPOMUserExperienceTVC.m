//
//  YPOMUserExperienceTVC.m
//  ypom
//
//  Created by Christoph Krey on 13.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOMUserExperienceTVC.h"
#import "YPOMTheme.h"
#import "YPOMAppDelegate.h"

@interface YPOMUserExperienceTVC ()
@property (weak, nonatomic) IBOutlet UITextField *selectedTheme;
@property (weak, nonatomic) IBOutlet UISegmentedControl *notificationLevel;

@end

@implementation YPOMUserExperienceTVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.selectedTheme.text = delegate.theme.selected;
    self.notificationLevel.selectedSegmentIndex = delegate.notificationLevel;
}

- (IBAction)notificationLevelChanged:(UISegmentedControl *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    delegate.notificationLevel =
    sender.selectedSegmentIndex;
}
@end
