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
#import "OSodiumSign.h"
#import "OSodiumBox.h"
#import <AddressBook/AddressBook.h>

#include "isutf8.h"

@interface YPOMMessagesTVC () <YPOMdelegate>
@property (weak, nonatomic) YPOMNewTVCell *selectedCellForImage;
@end

@implementation YPOMMessagesTVC 

- (void)setUser:(User *)user
{
    _user = user;
    
    if (![Message existsMessageWithTimestamp:[NSDate dateWithTimeIntervalSince1970:FUTURE]
                                    outgoing:YES
                                   belongsTo:user
                      inManagedObjectContext:user.managedObjectContext]) {
        [Message messageWithContent:nil
                        contentType:nil
                          timestamp:[NSDate dateWithTimeIntervalSince1970:FUTURE]
                           outgoing:YES
                          belongsTo:user
             inManagedObjectContext:user.managedObjectContext];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    self.fetchedResultsController = nil;
    self.title = [self.user name];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    self.view.backgroundColor = delegate.theme.backgroundColor;
    delegate.listener = self;
    
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
    /*
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    if (self.user.online) {
        if ([self.user.online boolValue]) {
            self.navigationController.navigationBar.barTintColor = delegate.theme.onlineColor;
        } else {
            self.navigationController.navigationBar.barTintColor = delegate.theme.offlineColor;
        }
    } else {
        self.navigationController.navigationBar.barTintColor = delegate.theme.unknownColor;

    }
     */
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)setupFRC
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Message" inManagedObjectContext:delegate.managedObjectContext];
    [fetchRequest setEntity:entity];

    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"belongsTo = %@", self.user];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"outgoing" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor1, sortDescriptor2];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
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
    Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        if (![message.outgoing boolValue] && ![message.seen boolValue]) {
            message.seen = @(TRUE);
            YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
            OSodiumBox *box = [[OSodiumBox alloc] init];
            box.pubkey = message.belongsTo.pubkey;
            box.seckey = delegate.myself.myUser.seckey;
            
            NSError *error;
            NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
            jsonObject[@"_type"] = @"see";
            jsonObject[@"timestamp"] = [NSString stringWithFormat:@"%.3f", [message.timestamp timeIntervalSince1970]];
            
            box.secret = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
            
            OSodiumSign *sign = [[OSodiumSign alloc] init];
            sign.verkey = delegate.myself.myUser.verkey;
            sign.sigkey = delegate.myself.myUser.sigkey;
            sign.secret = [box boxOnWire];
            
            [delegate.session publishData:[[sign signOnWire] base64EncodedDataWithOptions:0]
                                  onTopic:[NSString stringWithFormat:@"ypom/%@/%@",
                                           message.belongsTo.identifier,
                                           delegate.myself.myUser.identifier]
                                   retain:NO
                                      qos:2];
        }
    }

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
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;

    UILabel *timestamp = (UILabel *)[cell.contentView viewWithTag:2];
    timestamp.text = [self statusText:message];
    timestamp.textColor = delegate.theme.textColor;

    UILabel *text = (UILabel *)[cell.contentView viewWithTag:1];
    text.lineBreakMode = NSLineBreakByWordWrapping;
    text.numberOfLines = 0;
    text.preferredMaxLayoutWidth = cell.frame.size.width * 0.8;
    
    text.text = [message textOfMessage];
    text.textColor = delegate.theme.textColor;

    [text sizeToFit];
    [timestamp sizeToFit];
    [cell.contentView sizeToFit];
    [cell sizeToFit];
    
    [self colorCell:cell outgoing:[message.outgoing boolValue] acknowledged:[message.acknowledged boolValue] delivered:[message.delivered boolValue]];
}

- (void)configureImageCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;

    UILabel *timestamp = (UILabel *)[cell.contentView viewWithTag:2];
    timestamp.text = [self statusText:message];
    timestamp.textColor = delegate.theme.textColor;
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    
    UIImage *image = [UIImage imageWithData:message.content];
    
    double viewWidth = imageView.bounds.size.width - 20 - 20;
    double imageWidth = image.size.width;
    double widthScale = imageWidth / viewWidth;
    
    double viewHeight = imageView.bounds.size.height -7 - 8*2 - 12 - 7;
    double imageHeight = image.size.height;
    double heightScale = imageHeight / viewHeight;

    imageView.image = [UIImage imageWithData:message.content scale:MAX(widthScale, heightScale)];
    
    [imageView sizeToFit];
    [timestamp sizeToFit];
    [cell.contentView sizeToFit];
    [cell sizeToFit];
    
    [self colorCell:cell outgoing:[message.outgoing boolValue] acknowledged:[message.acknowledged boolValue] delivered:[message.delivered boolValue]];
    
}

- (void)colorCell:(UITableViewCell *)cell outgoing:(BOOL)outgoing acknowledged:(BOOL)acknowledged delivered:(BOOL)delivered
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;

    if (outgoing) {
        cell.backgroundColor = delegate.theme.myColor;
    } else {
        cell.backgroundColor = delegate.theme.yourColor;
    }
}

- (NSString *)statusText:(Message *)message
{
    return [NSString stringWithFormat:@"%@%@%@ %@ (%lu)",
            [message.delivered boolValue] ? @"✔︎": @"",
            [message.acknowledged boolValue] ? @"✔︎": @"",
            [message.seen boolValue] ? @"✔︎": @"",
            [NSDateFormatter localizedStringFromDate:message.timestamp
                                           dateStyle:NSDateFormatterShortStyle
                                           timeStyle:NSDateFormatterMediumStyle],
            (unsigned long)message.content.length];
}


- (void)configureNewMessageCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    UITextField *text = (UITextField *)[cell viewWithTag:1];
    text.text = @"";
    text.delegate = self;
    
    if ([cell respondsToSelector:@selector(setMessage:)]) {
        [cell performSelector:@selector(setMessage:) withObject:message];
    }
    cell.backgroundColor = delegate.theme.myColor;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return YES;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([message.timestamp timeIntervalSince1970] == FUTURE) {
        return 44;
    } else {
        NSRange range = [message.contenttype rangeOfString:@"image" options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound) {
            return 7 + 100 + 8 + 12 + 7;
        } else {
            NSString *text = [message textOfMessage];
            NSStringDrawingContext *sdc = [[NSStringDrawingContext alloc] init];
            sdc.minimumScaleFactor = 1.0;
            
            UILabel *textLabel = [[UILabel alloc] init];
            textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            textLabel.text = text;
            CGRect rect = [textLabel textRectForBounds:
                           CGRectMake(0, 0, tableView.frame.size.width * 0.8, tableView.frame.size.height)
                                limitedToNumberOfLines:0];
            
            return 7 + ceil(rect.size.height) + 8 + 12 + 7;
        }
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:^(void){
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        NSLog(@"image: w%f h%f s%f o%d", image.size.width, image.size.height, image.scale, image.imageOrientation);
        
        YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;

        UIImage *imageToSend;

        /* 
         * need to do some work here to downsize the image
         */
        
        double viewWidth = delegate.imageSize;
        double imageWidth = image.size.width;
        double widthScale = viewWidth / imageWidth;
        
        double viewHeight = delegate.imageSize;
        double imageHeight = image.size.height;
        double heightScale = viewHeight / imageHeight;
        
        double imageScale = MIN(widthScale, heightScale);
                
        NSLog(@"scales: w%f h%f", widthScale, heightScale);
        
        if (image.CGImage) {
            NSLog(@"CGImage");
            
            CGRect r = CGRectMake(0, 0, imageWidth, imageHeight);
            if (imageScale < 1.0) {
                r.size = CGSizeMake(r.size.width*imageScale, r.size.height*imageScale);
            }
            NSLog(@"scales: w%f h%f", r.size.width, r.size.height);

            UIGraphicsBeginImageContext(r.size);
            CGContextRef cRef = UIGraphicsGetCurrentContext();
            CGContextSaveGState(cRef);

            CGContextTranslateCTM(cRef, r.size.width/2, r.size.height/2);
            CGContextRotateCTM(cRef, (image.imageOrientation % 4) * -M_PI / 2);
            CGContextScaleCTM(cRef, 1.0, image.imageOrientation > 3 ? 1.0 : -1.0);
            CGRect drawRect;
            if (image.imageOrientation % 2) {
                drawRect = CGRectMake(-r.size.height / 2, -r.size.width / 2, r.size.height, r.size.width);

            } else {
                drawRect = CGRectMake(-r.size.width / 2, -r.size.height / 2, r.size.width, r.size.height);

            }
            CGContextDrawImage(cRef, drawRect, image.CGImage);

            CGContextRestoreGState(cRef);
            imageToSend = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }

        NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
        NSDate *timestamp = [NSDate date];
        jsonObject[@"_type"] = @"msg";
        jsonObject[@"timestamp"] = [NSString stringWithFormat:@"%.3f", [timestamp timeIntervalSince1970]];
        
        if (imageToSend) {
            NSLog(@"imageToSend: w%f h%f s%f", imageToSend.size.width, imageToSend.size.height, imageToSend.scale);
            
            jsonObject[@"content"] = [UIImagePNGRepresentation(imageToSend) base64EncodedStringWithOptions:0];
            jsonObject[@"content-type"] = @"image/png";
            
            NSLog(@"contentsize: %lu", (unsigned long)[jsonObject[@"content"] length]);

            [self sendAny:jsonObject to:self.selectedCellForImage.message.belongsTo from:delegate.myself.myUser];
        } else {
            jsonObject[@"content"] = [[@"cannot convert image" dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
            jsonObject[@"content-type"] = @"text/plain; charset:\"utf-8\"";
            
            NSLog(@"contentsize: %lu", (unsigned long)[jsonObject[@"content"] length]);
            
        }
        [self sendAny:jsonObject to:self.selectedCellForImage.message.belongsTo from:delegate.myself.myUser];
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
    if (text.text.length) {
        [text resignFirstResponder];
        
        UIView *view2 = view.superview;
        YPOMNewTVCell *newTVCell = (YPOMNewTVCell *)view2.superview;
        
        NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
        NSDate *timestamp = [NSDate date];
        jsonObject[@"_type"] = @"msg";
        jsonObject[@"timestamp"] = [NSString stringWithFormat:@"%.3f", [timestamp timeIntervalSince1970]];
        jsonObject[@"content"] = [[text.text dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
        jsonObject[@"content-type"] =@"text/plain; charset:\"utf-8\"";
        
        YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
        [self sendAny:jsonObject to:newTVCell.message.belongsTo from:delegate.myself.myUser];
        text.text = @"";
    }
}

- (void)sendAny:(NSDictionary *)jsonObject to:(User *)to from:(User *)from
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    OSodiumBox *box = [[OSodiumBox alloc] init];
    box.pubkey = to.pubkey;
    box.seckey = from.seckey;
    
    NSError *error;
    box.secret = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
    
    OSodiumSign *sign = [[OSodiumSign alloc] init];
    sign.verkey = from.verkey;
    sign.sigkey = from.sigkey;
    sign.secret = [box boxOnWire];
    
    UInt16 msgId = [delegate.session publishData:[[sign signOnWire] base64EncodedDataWithOptions:0]
                                         onTopic:[NSString stringWithFormat:@"ypom/%@/%@",
                                                  to.identifier,
                                                  from.identifier]
                                          retain:NO
                                             qos:2];
    
    Message *message = [Message messageWithContent:[[NSData alloc] initWithBase64EncodedData:jsonObject[@"content"]
                                                                                     options:0]
                                       contentType:jsonObject[@"content-type"]
                                         timestamp:[NSDate dateWithTimeIntervalSince1970:
                                                    [jsonObject[@"timestamp"] doubleValue]]
                                          outgoing:YES
                                         belongsTo:to
                            inManagedObjectContext:to.managedObjectContext];
    
    message.msgid = @(msgId);
    if (msgId) {
        message.delivered = @(FALSE);
    } else {
        message.delivered = @(TRUE);
    }
    [delegate sendPush:to];
    
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
- (IBAction)addressbookPressed:(UIBarButtonItem *)sender {
    ABPeoplePickerNavigationController *picker =
    [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    
    [self presentViewController:picker animated:YES completion:^{
        //
    }];
}

- (void)peoplePickerNavigationControllerDidCancel:
(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}


- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    
    self.user.abRecordId = @(ABRecordGetRecordID(person));
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate saveContext];
    
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
    
    return NO;
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}
@end
