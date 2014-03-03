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
    NSSortDescriptor *sortDescriptor0 = [[NSSortDescriptor alloc] initWithKey:@"belongsTo.belongsTo.host" ascending:YES];
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"belongsTo.belongsTo.port" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"belongsTo.name" ascending:YES];
    NSSortDescriptor *sortDescriptor3 = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSSortDescriptor *sortDescriptor4 = [[NSSortDescriptor alloc] initWithKey:@"out" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor0, sortDescriptor1, sortDescriptor2, sortDescriptor3, sortDescriptor4];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:delegate.managedObjectContext
                                                                                                  sectionNameKeyPath:@"url"
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
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [YPOMMessagesTVC dataToString:message.content]];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",
                                     [NSDateFormatter localizedStringFromDate:message.timestamp
                                                                    dateStyle:NSDateFormatterShortStyle
                                                                    timeStyle:NSDateFormatterMediumStyle]];
        if ([message.out boolValue]) {
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
    
    return [NSString stringWithFormat:@"%@:%@/%@", message.belongsTo.belongsTo.host, message.belongsTo.belongsTo.port, message.belongsTo.name];
}


+ (NSString *)dataToString:(NSData *)data
{
    for (int i = 0; i < data.length; i++) {
        char c;
        [data getBytes:&c range:NSMakeRange(i, 1)];
    }
    
    NSString *message = [[NSString alloc] init];
    
    for (int i = 0; i < data.length; i++) {
        char c;
        [data getBytes:&c range:NSMakeRange(i, 1)];
        message = [message stringByAppendingFormat:@"%c", c];
    }
    
    if (isutf8((unsigned char*)[data bytes], data.length) == 0) {
        const char *cp = [message cStringUsingEncoding:NSISOLatin1StringEncoding];
        if (cp) {
            NSString *u = [NSString stringWithUTF8String:cp];
            return [NSString stringWithFormat:@"%@", u];
        } else {
            return [NSString stringWithFormat:@"%@", [data description]];
        }
    }
    return [NSString stringWithFormat:@"%@", [data description]];
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
    jsonObject[@"payload"] = [[text.text dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
    NSData *e = [ypom box:data];
    NSString *b64 = [e base64EncodedStringWithOptions:0];
    NSString *n64 = [ypom.n base64EncodedStringWithOptions:0];

    UInt16 msgId = [delegate.session publishData:[[NSString stringWithFormat:@"%@:%@", n64, b64]
                                                  dataUsingEncoding:NSUTF8StringEncoding]
                                         onTopic:[NSString stringWithFormat:@"ypom/%@/%@/%@/%@/%@/%@",
                                                  newTVCell.message.belongsTo.belongsTo.host,
                                                  newTVCell.message.belongsTo.belongsTo.port,
                                                  newTVCell.message.belongsTo.name,
                                                  delegate.myself.myUser.belongsTo.host,
                                                  delegate.myself.myUser.belongsTo.port,
                                                  delegate.myself.myUser.name]
                                          retain:NO
                                             qos:2];
    
    Message *message = [Message messageWithContent:[[NSData alloc]
                                                    initWithBase64EncodedString:jsonObject[@"payload"] options:0]
                                         timestamp:[NSDate dateWithTimeIntervalSince1970:[jsonObject[@"timestamp"] doubleValue]]
                                               out:YES
                                         belongsTo:newTVCell.message.belongsTo
                            inManagedObjectContext:delegate.managedObjectContext];
    
    message.msgid = @(msgId);
    if (msgId) {
        message.delivered = @(FALSE);
    } else {
        message.delivered = @(TRUE);
    }
    
    newTVCell.message.content = [[NSData alloc] init];
    
    [delegate saveContext];
    
}

- (IBAction)keyboardReturn:(UITextField *)sender {
    [sender resignFirstResponder];
}


@end
