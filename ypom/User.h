//
//  User.h
//  ypom
//
//  Created by Christoph Krey on 15.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Device, Group, Message, Myself;

@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * abRecordId;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSData * pubkey;
@property (nonatomic, retain) NSData * seckey;
@property (nonatomic, retain) NSData * sigkey;
@property (nonatomic, retain) NSData * verkey;
@property (nonatomic, retain) NSSet *hasMessages;
@property (nonatomic, retain) Myself *me;
@property (nonatomic, retain) NSSet *hasDevices;
@property (nonatomic, retain) NSSet *hasGroups;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addHasMessagesObject:(Message *)value;
- (void)removeHasMessagesObject:(Message *)value;
- (void)addHasMessages:(NSSet *)values;
- (void)removeHasMessages:(NSSet *)values;

- (void)addHasDevicesObject:(Device *)value;
- (void)removeHasDevicesObject:(Device *)value;
- (void)addHasDevices:(NSSet *)values;
- (void)removeHasDevices:(NSSet *)values;

- (void)addHasGroupsObject:(Group *)value;
- (void)removeHasGroupsObject:(Group *)value;
- (void)addHasGroups:(NSSet *)values;
- (void)removeHasGroups:(NSSet *)values;

@end
