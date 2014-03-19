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
@property (weak, nonatomic) IBOutlet UISegmentedControl *imageSize;

@end

@implementation YPOMUserExperienceTVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.selectedTheme.text = delegate.theme.name;
    self.notificationLevel.selectedSegmentIndex = delegate.notificationLevel;
    
    double size = 320;
    for (self.imageSize.selectedSegmentIndex = 0; size < delegate.imageSize; self.imageSize.selectedSegmentIndex++) {
        size *= 2;
    }
    self.view.backgroundColor = delegate.theme.backgroundColor;
    self.tableView.tintColor = delegate.theme.yourColor;
}

- (IBAction)notificationLevelChanged:(UISegmentedControl *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    delegate.notificationLevel =
    sender.selectedSegmentIndex;
}
- (IBAction)imageSizeChanged:(UISegmentedControl *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    double size = 320;
    for (NSUInteger u = sender.selectedSegmentIndex; u > 0; u--) {
        size *= 2;
    }
    delegate.imageSize = size;
}
@end
