//
//  YPOMInviteMembersTVC.m
//  ypom
//
//  Created by Christoph Krey on 21.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOMInviteMembersTVC.h"
#import "YPOMAppDelegate.h"
#import "Group+Create.h"
#import "UserGroup.h"
#import "User+Create.h"
#import "OSodiumBox.h"
#import "OSodiumSign.h"

@interface YPOMInviteMembersTVC () <YPOMdelegate>

@end

@implementation YPOMInviteMembersTVC

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

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)setupFRC
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:delegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isGroup = NIL"];
    
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewMember" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    User *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    cell.textLabel.text = [NSString stringWithFormat:@"👤%@", [user displayName]];
    cell.textLabel.textColor = delegate.theme.textColor;
    
    if ([user.identifier isEqualToString:delegate.myself.myUser.identifier]) {
        cell.backgroundColor = delegate.theme.myColor;
    } else {
        cell.backgroundColor = delegate.theme.yourColor;
    }
    
    for (UserGroup *userGroup in user.hasGroups) {
        if (userGroup.group == self.group) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    User *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    OSodiumBox *box = [[OSodiumBox alloc] init];
    box.pubkey = user.pubkey;
    box.seckey = delegate.myself.myUser.seckey;
    
    NSError *error;
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    jsonObject[@"_type"] = @"inv";
    jsonObject[@"timestamp"] = [NSString stringWithFormat:@"%.3f",
                                [[NSDate date] timeIntervalSince1970]];
    NSMutableArray *members = [[NSMutableArray alloc] init];
    for (UserGroup *userGroup in self.group.hasUsers) {
        if (userGroup.group == self.group) {
            [members addObject:userGroup.user.identifier];
        }
    }
    NSDictionary *group = @{
                            @"id": self.group.identifier,
                            @"name": self.group.name,
                            @"members":members
                            };
    jsonObject[@"group"] = group;
    
    box.secret = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
    
    OSodiumSign *sign = [[OSodiumSign alloc] init];
    sign.verkey = delegate.myself.myUser.verkey;
    sign.sigkey = delegate.myself.myUser.sigkey;
    sign.secret = [box boxOnWire];
    
    [delegate.session publishData:[[sign signOnWire] base64EncodedDataWithOptions:0]
                          onTopic:[NSString stringWithFormat:@"ypom/%@/%@",
                                   user.identifier,
                                   delegate.myself.myUser.identifier]
                           retain:NO
                              qos:2];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


@end
