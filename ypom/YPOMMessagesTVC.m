//
//  YPOMMessagesTVC.m
//  YPOM
//
//  Created by Christoph Krey on 12.11.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import "YPOMMessagesTVC.h"
#import "User+Create.h"
#import "Broker+Create.h"
#import "Message+Create.h"
#import "YPOMAppDelegate.h"
#import "YPOMNewTVCell.h"
#import "YPOM.h"
#import "YPOM+Wire.h"
#import "NSString+stringWithData.h"

#include "isutf8.h"

@interface YPOMMessagesTVC ()
@end

@implementation YPOMMessagesTVC

- (void)viewWillAppear:(BOOL)animated
{
    self.fetchedResultsController = nil;
    [self.tableView reloadData];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)setupFRC
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Message" inManagedObjectContext:delegate.managedObjectContext];
    [fetchRequest setEntity:entity];

    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"belongsTo.selected = TRUE"];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"belongsTo.name" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSSortDescriptor *sortDescriptor3 = [[NSSortDescriptor alloc] initWithKey:@"outgoing" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor1, sortDescriptor2, sortDescriptor3];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:delegate.managedObjectContext
                                                                                                  sectionNameKeyPath:@"belongsTo.name"
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
    Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];

    UITableViewCell *cell;
    if ([message.timestamp timeIntervalSince1970] == FUTURE) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NewMessage" forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Message" forIndexPath:indexPath];
    }
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([cell.reuseIdentifier isEqualToString:@"Message"]) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [NSString stringWithData:message.content]];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",
                                     [NSDateFormatter localizedStringFromDate:message.timestamp
                                                                    dateStyle:NSDateFormatterShortStyle
                                                                    timeStyle:NSDateFormatterMediumStyle]];
        if ([message.outgoing boolValue]) {
            if ([message.delivered boolValue]) {
                cell.backgroundColor = [UIColor colorWithRed:0.75 green:0.75 blue:1.0 alpha:1.0];
            } else {
                cell.backgroundColor = [UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:1.0];
            }
        } else {
            cell.backgroundColor = [UIColor colorWithRed:0.75 green:1.0 blue:0.75 alpha:1.0];
        }
        
        cell.accessoryType = [message.acknowledged boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    } else {
        UITextField *text = (UITextField *)[cell viewWithTag:1];
        text.text = @"";
        
        if ([cell respondsToSelector:@selector(setMessage:)]) {
            [cell performSelector:@selector(setMessage:) withObject:message];
        }
     }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> info = [self.fetchedResultsController sections][section];
    
    Message *message = [[info objects] firstObject];
    
    return message ? [NSString stringWithFormat:@"%@ (%@)", message.belongsTo.name, [message.belongsTo base32EncodedPk]] :
    @"no users selected or no messages available";
}



- (IBAction)send:(UIButton *)sender {
    UIView *view = (UIView *)sender.superview;
    UITextView *text = (UITextView *)[view viewWithTag:1];
    
    UIView *view2 = view.superview;
    YPOMNewTVCell *newTVCell = (YPOMNewTVCell *)view2.superview;
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    YPOM *ypom = [[YPOM alloc] init];
    ypom.pk = newTVCell.message.belongsTo.pk;
    ypom.sk = delegate.myself.myUser.sk;
    
    NSError *error;
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    NSDate *timestamp = [NSDate date];
    jsonObject[@"_type"] = @"msg";
    jsonObject[@"timestamp"] = [NSString stringWithFormat:@"%.3f", [timestamp timeIntervalSince1970]];
    jsonObject[@"content"] = [[text.text dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    
    ypom.message = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
    
    UInt16 msgId = [delegate.session publishData:[[ypom wireString] dataUsingEncoding:NSUTF8StringEncoding]
                                         onTopic:[NSString stringWithFormat:@"ypom/%@/%@",
                                                  [newTVCell.message.belongsTo base32EncodedPk],
                                                  [delegate.myself.myUser base32EncodedPk]]
                                          retain:NO
                                             qos:2];
    
    Message *message = [Message messageWithContent:[[NSData alloc]
                                                    initWithBase64EncodedString:jsonObject[@"content"]
                                                    options:0]
                                       contentType:nil
                                         timestamp:[NSDate dateWithTimeIntervalSince1970:
                                                    [jsonObject[@"timestamp"] doubleValue]]
                                          outgoing:YES
                                         belongsTo:newTVCell.message.belongsTo
                            inManagedObjectContext:delegate.managedObjectContext];
    
    message.msgid = @(msgId);
    if (msgId) {
        message.delivered = @(FALSE);
    } else {
        message.delivered = @(TRUE);
    }
    
    [delegate saveContext];
}

- (IBAction)keyboardReturn:(UITextField *)sender {
    [sender resignFirstResponder];
}


@end
