//
//  Message+Create.h
//  ypom
//
//  Created by Christoph Krey on 27.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "Message.h"

#define FUTURE 1111.0*365.0*24.0*60.0*60.0

@interface Message (Create)
+ (Message *)messageWithContent:(NSData *)content
                    contentType:(NSString *)contentType
                      timestamp:(NSDate *)timestamp
                       outgoing:(BOOL)outgoing
                         belongsTo:(User *)user
inManagedObjectContext:(NSManagedObjectContext *)context;

+ (Message *)existsMessageWithTimestamp:(NSDate *)timestamp
                               outgoing:(BOOL)outgoing
                              belongsTo:(User *)user
                 inManagedObjectContext:(NSManagedObjectContext *)context;

+ (Message *)existsMessageWithTimestamp:(NSDate *)timestamp
                              belongsTo:(User *)user
                 inManagedObjectContext:(NSManagedObjectContext *)context;

+ (Message *)existsMessageWithMsgId:(UInt16)msgId
             inManagedObjectContext:(NSManagedObjectContext *)context;

- (NSString *)textOfMessage;

@end
