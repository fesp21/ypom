//
//  Message+Create.m
//  ypom
//
//  Created by Christoph Krey on 27.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "Message+Create.h"
#import "User+Create.h"
#import "NSString+stringWithData.h"

@implementation Message (Create)
+ (Message *)messageWithContent:(NSData *)content
                    contentType:(NSString *)contentType
                      timestamp:(NSDate *)timestamp
                       outgoing:(BOOL)outgoing
                         belongsTo:(User *)user
         inManagedObjectContext:(NSManagedObjectContext *)context
{
    Message *message = [Message existsMessageWithTimestamp:timestamp
                                                  outgoing:outgoing
                                                    belongsTo:user
                                    inManagedObjectContext:context];
    
    if (!message) {
        
        message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:context];
        
        message.timestamp = timestamp;
        message.outgoing = @(outgoing);
        message.content = content;
        message.contenttype = contentType;
        message.belongsTo = user;
        user.lastMessage = timestamp;
        message.delivered = @(NO);
        message.acknowledged = @(NO);
        message.seen = @(NO);
        message.msgid = @(0);
    }
    
    return message;
}

+ (Message *)existsMessageWithTimestamp:(NSDate *)timestamp
                               outgoing:(BOOL)outgoing
                              belongsTo:(User *)user
                 inManagedObjectContext:(NSManagedObjectContext *)context
{
    Message *message = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"timestamp = %@ AND outgoing = %@ AND belongsTo = %@",
                         timestamp, @(outgoing), user];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches) {
        // handle error
    } else {
        if ([matches count]) {
            message = [matches lastObject];
        }
    }
    
    return message;
}

+ (Message *)existsMessageWithTimestamp:(NSDate *)timestamp
                              belongsTo:(User *)user
                 inManagedObjectContext:(NSManagedObjectContext *)context
{
    Message *message = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"timestamp = %@ AND belongsTo = %@",
                         timestamp, user];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches) {
        // handle error
    } else {
        if ([matches count]) {
            message = [matches lastObject];
        }
    }
    
    return message;
}

+ (Message *)existsMessageWithMsgId:(UInt16)msgId
             inManagedObjectContext:(NSManagedObjectContext *)context
{
    Message *message = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"msgid = %@ AND outgoing = TRUE and delivered = FALSE",
                         @(msgId)];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches) {
        // handle error
    } else {
        if ([matches count]) {
            message = [matches lastObject];
        }
    }
    
    return message;
}

- (NSString *)textOfMessage
{
    NSString *text;
    if (!self.contenttype) {
        text = [NSString stringWithData:self.content];
    } else {
        NSRange range = [self.contenttype rangeOfString:@"text/plain" options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound) {
            NSRange range = [self.contenttype rangeOfString:@"charset:\"utf-8\"" options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound) {
                char *cp = malloc(self.content.length + 1);
                if (cp) {
                    [self.content getBytes:cp length:self.content.length];
                    cp[self.content.length] = 0;
                    text = [NSString stringWithUTF8String:cp];
                    free(cp);
                } else {
                    text = [NSString stringWithFormat:@"UTF-8 can't malloc %lu",
                            (unsigned long)self.content.length + 1];
                }
            } else {
                text = [NSString stringWithData:self.content];
            }
        } else {
            text = [NSString stringWithFormat:@"content-type: %@",
                    self.contenttype];
        }
    }
    return text;
}

@end
