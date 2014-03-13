//
//  YPOMThemesTVC.m
//  ypom
//
//  Created by Christoph Krey on 13.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOMThemesTVC.h"
#import "YPOMTheme.h"
#import "YPOMAppDelegate.h"

@interface YPOMThemesTVC ()

@end

@implementation YPOMThemesTVC


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;

    return [delegate.theme numberOfThemes];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"theme" forIndexPath:indexPath];
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    cell.textLabel.text = [delegate.theme nameOfThemeNumber:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    delegate.theme.selected = [delegate.theme nameOfThemeNumber:indexPath.row];

}

@end
