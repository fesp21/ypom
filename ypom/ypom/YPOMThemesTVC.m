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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.view.backgroundColor = delegate.theme.backgroundColor;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;

    return [delegate.themes numberOfThemes];
}

#define IMAGESIZE 48
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"theme" forIndexPath:indexPath];
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    YPOMTheme *theme = [delegate.themes selectTheme:[delegate.themes nameOfThemeNumber:indexPath.row]];
    cell.textLabel.text = theme.name;
    cell.textLabel.textColor = theme.textColor;
    cell.backgroundColor = theme.yourColor;
    
    UIGraphicsBeginImageContext(CGSizeMake(IMAGESIZE, IMAGESIZE));
    CGContextRef cRef = UIGraphicsGetCurrentContext();
    CGContextSaveGState(cRef);
    
    CGContextBeginPath(cRef);
    CGContextSetFillColorWithColor(cRef, theme.backgroundColor.CGColor);
    CGContextAddRect(cRef, CGRectMake(0, 0, IMAGESIZE, IMAGESIZE));
    CGContextDrawPath(cRef, kCGPathFill);

    CGContextBeginPath(cRef);
    CGContextSetFillColorWithColor(cRef, theme.alertColor.CGColor);
    CGContextAddRect(cRef, CGRectMake(4, IMAGESIZE / 4 * 0, IMAGESIZE / 2 - 8, IMAGESIZE / 4));
    CGContextDrawPath(cRef, kCGPathFill);
    
    CGContextBeginPath(cRef);
    CGContextSetFillColorWithColor(cRef, theme.textColor.CGColor);
    CGContextAddRect(cRef, CGRectMake(IMAGESIZE / 2 + 4, IMAGESIZE / 4 * 0, IMAGESIZE / 2 - 8, IMAGESIZE / 4));
    CGContextDrawPath(cRef, kCGPathFill);

    CGContextBeginPath(cRef);
    CGContextSetFillColorWithColor(cRef, theme.onlineColor.CGColor);
    CGContextAddRect(cRef, CGRectMake(4, IMAGESIZE / 4 * 1, IMAGESIZE / 2 - 8, IMAGESIZE / 4));
    CGContextDrawPath(cRef, kCGPathFill);
    
    CGContextBeginPath(cRef);
    CGContextSetFillColorWithColor(cRef, theme.offlineColor.CGColor);
    CGContextAddRect(cRef, CGRectMake(4, IMAGESIZE / 4 * 2, IMAGESIZE / 2 - 8, IMAGESIZE / 4));
    CGContextDrawPath(cRef, kCGPathFill);
    
    CGContextBeginPath(cRef);
    CGContextSetFillColorWithColor(cRef, theme.unknownColor.CGColor);
    CGContextAddRect(cRef, CGRectMake(4, IMAGESIZE / 4 * 3, IMAGESIZE / 2 - 8, IMAGESIZE / 4));
    CGContextDrawPath(cRef, kCGPathFill);

    CGContextBeginPath(cRef);
    CGContextSetFillColorWithColor(cRef, theme.myColor.CGColor);
    CGContextAddRect(cRef, CGRectMake(IMAGESIZE / 2 + 4, IMAGESIZE / 4 * 2, IMAGESIZE / 2 - 8, IMAGESIZE / 4));
    CGContextDrawPath(cRef, kCGPathFill);
    
    CGContextBeginPath(cRef);
    CGContextSetFillColorWithColor(cRef, theme.yourColor.CGColor);
    CGContextAddRect(cRef, CGRectMake(IMAGESIZE / 2 + 4, IMAGESIZE / 4 * 3, IMAGESIZE / 2 - 8, IMAGESIZE / 4));
    CGContextDrawPath(cRef, kCGPathFill);
    
    CGContextRestoreGState(cRef);

    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    delegate.theme = [delegate.themes selectTheme:[delegate.themes nameOfThemeNumber:indexPath.row]];
    self.view.backgroundColor = delegate.theme.backgroundColor;
    [self.tableView reloadData];
}

@end


