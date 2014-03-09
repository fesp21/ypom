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
#import "YPOMImageVC.h"

#include "isutf8.h"

@interface YPOMMessagesTVC ()
@property (weak, nonatomic) YPOMNewTVCell *selectedCellForImage;
@end

@implementation YPOMMessagesTVC 

- (void)viewWillAppear:(BOOL)animated
{
    self.fetchedResultsController = nil;
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.title = [NSString stringWithFormat:@"YPOM - %@", delegate.myself.myUser.name];
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
        NSRange range = [message.contenttype rangeOfString:@"image" options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"ImageMessage" forIndexPath:indexPath];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"Message" forIndexPath:indexPath];
        }
    }
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([cell.reuseIdentifier isEqualToString:@"NewMessage"]) {
        [self configureNewMessageCell:cell atIndexPath:indexPath];
    } else {
        if ([cell.reuseIdentifier isEqualToString:@"ImageMessage"]) {
            [self configureImageCell:cell atIndexPath:indexPath];
        } else {
            [self configureMessageCell:cell atIndexPath:indexPath];
        }
    }
}

- (void)configureMessageCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (!message.contenttype) {
        cell.textLabel.text = [NSString stringWithData:message.content];
    } else {
        NSRange range = [message.contenttype rangeOfString:@"text/plain" options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound) {
            NSRange range = [message.contenttype rangeOfString:@"charset:\"utf-8\"" options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound) {
                char *cp = malloc(message.content.length + 1);
                if (cp) {
                    [message.content getBytes:cp length:message.content.length];
                    cp[message.content.length] = 0;
                    cell.textLabel.text = [NSString stringWithUTF8String:cp];
                    free(cp);
                } else {
                    cell.textLabel.text = [NSString stringWithFormat:@"UTF-8 can't malloc %lu",
                                           (unsigned long)message.content.length + 1];
                }
            } else {
                cell.textLabel.text = [NSString stringWithData:message.content];
            }
        } else {
            cell.textLabel.text = [NSString stringWithFormat:@"content-type: %@",
                                   message.contenttype];
        }
    }
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",
                                 [NSDateFormatter localizedStringFromDate:message.timestamp
                                                                dateStyle:NSDateFormatterShortStyle
                                                                timeStyle:NSDateFormatterMediumStyle]];
    [self colorCell:cell outgoing:[message.outgoing boolValue] acknowledged:[message.acknowledged boolValue] delivered:[message.delivered boolValue]];
}

- (void)configureImageCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    UIImage *image = [UIImage imageWithData:message.content];
    
    double viewWidth = imageView.frame.size.width;
    double imageWidth = image.size.width;
    double widthScale = viewWidth / imageWidth;
    
    double viewHeight = imageView.frame.size.width;
    double imageHeight = image.size.width;
    double heightScale = viewHeight / imageHeight;
    
    imageView.image = [UIImage imageWithData:message.content scale:MIN(widthScale, heightScale)];
    [imageView sizeToFit];

    [self colorCell:cell outgoing:[message.outgoing boolValue] acknowledged:[message.acknowledged boolValue] delivered:[message.delivered boolValue]];
    [cell sizeToFit];
}

- (void)colorCell:(UITableViewCell *)cell outgoing:(BOOL)outgoing acknowledged:(BOOL)acknowledged delivered:(BOOL)delivered
{
    if (outgoing) {
        if (delivered) {
            cell.backgroundColor = [UIColor colorWithRed:0.75 green:0.75 blue:1.0 alpha:1.0];
        } else {
            cell.backgroundColor = [UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:1.0];
        }
    } else {
        cell.backgroundColor = [UIColor colorWithRed:0.75 green:1.0 blue:0.75 alpha:1.0];
    }
    
    cell.accessoryType = acknowledged ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}


- (void)configureNewMessageCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    UITextField *text = (UITextField *)[cell viewWithTag:1];
    text.text = @"";
    
    if ([cell respondsToSelector:@selector(setMessage:)]) {
        [cell performSelector:@selector(setMessage:) withObject:message];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> info = [self.fetchedResultsController sections][section];
    
    Message *message = [[info objects] firstObject];
    
    return message ? [NSString stringWithFormat:@"%@ (%@)", message.belongsTo.name, [message.belongsTo base32EncodedPk]] :
    @"no users selected or no messages available";
}

- (IBAction)image:(UIButton *)sender {
    UIView *view = (UIView *)sender.superview;
    UIView *view2 = view.superview;
    self.selectedCellForImage = (YPOMNewTVCell *)view2.superview;

    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    
    [self presentViewController:imagePicker animated:YES completion:^(void){
        // returned
    }];

}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"info: %@", info);

    UIImage *image = info[UIImagePickerControllerOriginalImage];
    UIImage *imageToSend;
    if (image.CGImage) {
        imageToSend = [UIImage imageWithCGImage:image.CGImage];
    } else if (image.CIImage) {
        imageToSend = [UIImage imageWithCIImage:image.CIImage];
    } else {
        imageToSend = image;
    }
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    YPOM *ypom = [[YPOM alloc] init];
    ypom.pk = self.selectedCellForImage.message.belongsTo.pk;
    ypom.sk = delegate.myself.myUser.sk;
    
    NSError *error;
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    NSDate *timestamp = [NSDate date];
    jsonObject[@"_type"] = @"msg";
    jsonObject[@"timestamp"] = [NSString stringWithFormat:@"%.3f", [timestamp timeIntervalSince1970]];
    jsonObject[@"content"] = [UIImagePNGRepresentation(imageToSend) base64EncodedStringWithOptions:0];
    jsonObject[@"content-type"] = @"image/png";
    
    ypom.message = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
    
    UInt16 msgId = [delegate.session publishData:[ypom wireData]
                                         onTopic:[NSString stringWithFormat:@"ypom/%@/%@",
                                                  [self.selectedCellForImage.message.belongsTo base32EncodedPk],
                                                  [delegate.myself.myUser base32EncodedPk]]
                                          retain:NO
                                             qos:2];
    
    Message *message = [Message messageWithContent:UIImagePNGRepresentation(imageToSend)
                                       contentType:jsonObject[@"content-type"]
                                         timestamp:[NSDate dateWithTimeIntervalSince1970:
                                                    [jsonObject[@"timestamp"] doubleValue]]
                                          outgoing:YES
                                         belongsTo:self.selectedCellForImage.message.belongsTo
                            inManagedObjectContext:delegate.managedObjectContext];
    
    message.msgid = @(msgId);
    if (msgId) {
        message.delivered = @(FALSE);
    } else {
        message.delivered = @(TRUE);
    }
    
    [delegate saveContext];
    [self dismissViewControllerAnimated:YES completion:^(void){
       //
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^(void){
        //
    }];
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
    jsonObject[@"content-type"] = @"text/plain; charset:\"utf-8\"";
    
    ypom.message = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
    
    UInt16 msgId = [delegate.session publishData:[ypom wireData]
                                         onTopic:[NSString stringWithFormat:@"ypom/%@/%@",
                                                  [newTVCell.message.belongsTo base32EncodedPk],
                                                  [delegate.myself.myUser base32EncodedPk]]
                                          retain:NO
                                             qos:2];
    
    Message *message = [Message messageWithContent:[text.text dataUsingEncoding:NSUTF8StringEncoding]
                                       contentType:jsonObject[@"content-type"]
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
    NSLog(@"sent message:%@", message);
    
    [delegate saveContext];
}

- (IBAction)keyboardReturn:(UITextField *)sender {
    [sender resignFirstResponder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        UITableViewCell *cell = (UITableViewCell *)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        if (indexPath) {
            Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];

            if ([segue.identifier isEqualToString:@"setImageData:"]) {
                if ([segue.destinationViewController respondsToSelector:@selector(setImageData:)]) {
                    [segue.destinationViewController performSelector:@selector(setImageData:)
                                                          withObject:message.content];
                }
            }
        }
    }

}

@end
