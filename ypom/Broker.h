//
//  Broker.h
//  ypom
//
//  Created by Christoph Krey on 02.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Broker : NSManagedObject

@property (nonatomic, retain) NSNumber * auth;
@property (nonatomic, retain) NSString * host;
@property (nonatomic, retain) NSString * passwd;
@property (nonatomic, retain) NSNumber * port;
@property (nonatomic, retain) NSNumber * tls;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSSet *hasUsers;
@end

@interface Broker (CoreDataGeneratedAccessors)

- (void)addHasUsersObject:(User *)value;
- (void)removeHasUsersObject:(User *)value;
- (void)addHasUsers:(NSSet *)values;
- (void)removeHasUsers:(NSSet *)values;

@end
