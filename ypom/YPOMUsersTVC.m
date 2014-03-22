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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.version.title =  [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"];

    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.listener = self;
    self.view.backgroundColor = delegate.theme.backgroundColor;
    self.fetchedResultsController = nil;
    [self.tableView reloadData];
    [self lineState];
    UITabBarItem *tbi = self.tabBarController.tabBar.items[0];
    [tbi setBadgeValue:nil];
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
            break;
        case -1:
            self.navigationController.navigationBar.barTintColor = delegate.theme.offlineColor;
            break;
        default:
            self.navigationController.navigationBar.barTintColor = delegate.theme.unknownColor;
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
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:delegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"identifier" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor1];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc]
                                                             initWithFetchRequest:fetchRequest
                                                             managedObjectContext:delegate.managedObjectContext
                                                             sectionNameKeyPath:nil
                                                             cacheName:nil];
    aFetchedResultsController.delegate = self;
    
    
	NSError *error = nil;
	if (![aFetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle     the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
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
        cell.textLabel.text = [NSString stringWithFormat:@"👤%@", [user displayName]];
    }
    cell.textLabel.textColor = delegate.theme.textColor;

    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", [user numberOfUnseenMessages]];
    cell.detailTextLabel.textColor = delegate.theme.textColor;

    if (user == delegate.myself.myUser || (user.isGroup && user.isGroup.belongsTo == delegate.myself.myUser)) {
        cell.backgroundColor = delegate.theme.myColor;
    } else {
        cell.backgroundColor = delegate.theme.yourColor;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


@end
