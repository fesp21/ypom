//
//  User.h
//  ypom
//
//  Created by Christoph Krey on 12.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Message, Myself;

@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * group;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * online;
@property (nonatomic, retain) NSData * pk;
@property (nonatomic, retain) NSData * sk;
@property (nonatomic, retain) NSData * dev;
@property (nonatomic, retain) NSSet *hasMessages;
@property (nonatomic, retain) Myself *me;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addHasMessagesObject:(Message *)value;
- (void)removeHasMessagesObject:(Message *)value;
- (void)addHasMessages:(NSSet *)values;
- (void)removeHasMessages:(NSSet *)values;

@end
