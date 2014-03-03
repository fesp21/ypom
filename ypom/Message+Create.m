//
//  Message+Create.m
//  ypom
//
//  Created by Christoph Krey on 27.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "Message+Create.h"
#import "User+Create.h"

@implementation Message (Create)
+ (Message *)messageWithContent:(NSData *)content
                      timestamp:(NSDate *)timestamp
                            out:(BOOL)out
                         belongsTo:(User *)user
         inManagedObjectContext:(NSManagedObjectContext *)context
{
    Message *message = [Message existsMessageWithTimestamp:timestamp
                                                       out:out
                                                    belongsTo:user
                                    inManagedObjectContext:context];
    
    if (!message) {
        
        message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:context];
        
        message.timestamp = timestamp;
        message.out = @(out);
        message.content = content;
        message.belongsTo = user;
        message.delivered = @(NO);
        message.acknowledged = @(NO);
        message.msgid = @(0);
    }
    
    return message;
}

+ (Message *)existsMessageWithTimestamp:(NSDate *)timestamp
                                    out:(BOOL)out
belongsTo:(User *)user
inManagedObjectContext:(NSManagedObjectContext *)context
{
    Message *message = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
    request.predicate = [NSPredicate predicateWithFormat:@"timestamp = %@ AND out = %@AND belongsTo = %@",
                         timestamp, @(out), user];
    
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
    request.predicate = [NSPredicate predicateWithFormat:@"msgid = %@ AND out = TRUE and delivered = FALSE",
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

- (NSString *)url
{
    return [NSString stringWithFormat:@"%@:%@", self.belongsTo.url, self.belongsTo.name];
}



@end
