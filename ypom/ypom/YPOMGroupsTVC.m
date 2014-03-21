//
//  YPOMGroupsTVC.m
//  ypom
//
//  Created by Christoph Krey on 21.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOMGroupsTVC.h"
#import "YPOMAppDelegate.h"
#import "Group+Create.h"
#import "UserGroup.h"
#import "YPOMGroupTVC.h"

@interface YPOMGroupsTVC () <YPOMdelegate>

@end

@implementation YPOMGroupsTVC

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.listener = self;
    self.view.backgroundColor = delegate.theme.backgroundColor;
    self.fetchedResultsController = nil;
    [self.tableView reloadData];
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
    Group *group = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([segue.identifier isEqualToString:@"setGroup:"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setGroup:)]) {
            [segue.destinationViewController performSelector:@selector(setGroup:)
                                                  withObject:group];
        }
    }
    if ([segue.identifier isEqualToString:@"setUser:"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setUser:)]) {
            [segue.destinationViewController performSelector:@selector(setUser:)
                                                  withObject:group.isUser];
        }
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)setupFRC
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Group" inManagedObjectContext:delegate.managedObjectContext];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Group" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Group *group = [self.fetchedResultsController objectAtIndexPath:indexPath];
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    cell.textLabel.text = group.name;
    cell.textLabel.textColor = delegate.theme.textColor;
    
    cell.detailTextLabel.text = group.identifier;
    cell.detailTextLabel.textColor = delegate.theme.textColor;
    
    cell.backgroundColor = delegate.theme.yourColor;
}

- (IBAction)addPressed:(UIBarButtonItem *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;

    [Group newGroupInManageObjectContext:delegate.managedObjectContext];
    
    [delegate saveContext];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Group *group = [self.fetchedResultsController objectAtIndexPath:indexPath];

        for (UserGroup *userGroup in group.hasUsers) {
            NSError *error;
            NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
            jsonObject[@"_type"] = @"leave";
            jsonObject[@"timestamp"] = [NSString stringWithFormat:@"%.3f",
                                        [[NSDate date] timeIntervalSince1970]];
            NSMutableArray *members = [[NSMutableArray alloc] init];
            for (UserGroup *userGroup in group.hasUsers) {
                [members addObject:userGroup.user.identifier];
            }
            NSDictionary *groupDictionary = @{
                                              @"id": group.identifier,
                                              @"name": group.name,
                                              @"members":members
                                              };
            jsonObject[@"group"] = groupDictionary;
            
            YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
            [delegate safeSend:[NSJSONSerialization dataWithJSONObject:jsonObject
                                                               options:0
                                                                 error:&error]
                            to:userGroup.user];
            [delegate sendPush:userGroup.user];
        }

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
