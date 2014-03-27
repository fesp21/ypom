//
//  YPOMUsersTVC.m
//  YPOM
//
//  Created by Christoph Krey on 12.11.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "YPOMUsersTVC.h"
#import "User+Create.h"
#import "Group+Create.h"
#import "Broker+Create.h"
#import "Message+Create.h"
#import "YPOMAppDelegate.h"
#import "YPOM.h"
#import <AddressBook/AddressBook.h>

@interface YPOMUsersTVC () <YPOMdelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *version;
@end

@implementation YPOMUsersTVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.version.title =  [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"];
    
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    self.view.backgroundColor = delegate.theme.backgroundColor;
    self.fetchedResultsController = nil;
    [self.tableView reloadData];
    [self lineState];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.listener = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.listener = nil;
}

- (void)lineState
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    switch (delegate.state) {
        case 1:
            self.navigationController.navigationBar.barTintColor = delegate.theme.onlineColor;
            self.tabBarController.tabBar.barTintColor = delegate.theme.onlineColor;
            break;
        default:
            self.navigationController.navigationBar.barTintColor = delegate.theme.offlineColor;
            self.tabBarController.tabBar.barTintColor = delegate.theme.onlineColor;
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    User *user = [self.fetchedResultsController objectAtIndexPath:indexPath];

    if ([segue.identifier isEqualToString:@"setUser:"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setUser:)]) {
            [segue.destinationViewController performSelector:@selector(setUser:)
                                                  withObject:user];
        }
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)setupFRC
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:delegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"lastMessage" ascending:NO];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"identifier" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor1, sortDescriptor2];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc]
                                                             initWithFetchRequest:fetchRequest
                                                             managedObjectContext:delegate.managedObjectContext
                                                             sectionNameKeyPath:nil
                                                             cacheName:nil];
    aFetchedResultsController.delegate = self;
    
    
	NSError *error = nil;
	if (![aFetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return aFetchedResultsController;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"User" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    User *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    if (user.isGroup) {
        cell.textLabel.text = [NSString stringWithFormat:@"👥%@", [user.isGroup displayName]];
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [user displayName]];
    }
    cell.textLabel.textColor = delegate.theme.textColor;

    Message *lastMessage = [Message existsMessageWithTimestamp:user.lastMessage belongsTo:user inManagedObjectContext:user.managedObjectContext];
        cell.detailTextLabel.text = lastMessage ? [lastMessage textOfMessage] : @"./.";
    
    if ([user numberOfUnseenMessages]) {
        cell.detailTextLabel.textColor = delegate.theme.alertColor;
    } else {
        cell.detailTextLabel.textColor = delegate.theme.textColor;
    }

    if (user == delegate.myself.myUser || (user.isGroup && user.isGroup.belongsTo == delegate.myself.myUser)) {
        cell.backgroundColor = delegate.theme.myColor;
    } else {
        cell.backgroundColor = delegate.theme.yourColor;
    }
    
    NSData *imageData = [user imageData];
    cell.imageView.image = imageData ? [UIImage imageWithData:imageData] : [UIImage imageNamed:@"icon-40"];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    User *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    if (user == delegate.myself.myUser) {
        return NO;
    } else {
        return YES;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.noupdate = TRUE;
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
        [delegate saveContext];
    }
    self.noupdate = FALSE;
    [self.tableView reloadData];
}


@end
