//
//  YPOMUsersTVC.m
//  YPOM
//
//  Created by Christoph Krey on 12.11.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "YPOMUsersTVC.h"
#import "User+Create.h"
#import "Broker+Create.h"
#import "Message+Create.h"
#import "YPOMAppDelegate.h"
#import "YPOM.h"

@interface YPOMUsersTVC () <YPOMdelegate>
@end

@implementation YPOMUsersTVC

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.listener = self;

    self.title = [NSString stringWithFormat:@"YPOM-%@-%@", delegate.myself.myUser.name, delegate.broker.host];
    [self lineState];
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
            self.navigationController.navigationBar.titleTextAttributes =
            @{NSForegroundColorAttributeName: [UIColor greenColor]};
            break;
        case -1:
            self.navigationController.navigationBar.titleTextAttributes =
            @{NSForegroundColorAttributeName: [UIColor redColor]};
            break;
        default:
            self.navigationController.navigationBar.titleTextAttributes =
            @{NSForegroundColorAttributeName: [UIColor yellowColor]};
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
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
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
    NSLog(@"usr n:%@ p:%@ s:%@ o:%@", user.name, user.pk, user.sk, user.online);
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", user.name];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[user.hasMessages count] - 1];
    
    cell.backgroundColor = [UIColor grayColor];
    if (user.online) {
        if ([user.online boolValue]) {
            cell.backgroundColor = [UIColor greenColor];
        } else {
            cell.backgroundColor = [UIColor redColor];
        }
    }
}


@end
