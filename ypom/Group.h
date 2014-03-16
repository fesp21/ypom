//
//  Group.h
//  ypom
//
//  Created by Christoph Krey on 15.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Group : NSManagedObject

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSSet *hasUsers;
@end

@interface Group (CoreDataGeneratedAccessors)

- (void)addHasUsersObject:(User *)value;
- (void)removeHasUsersObject:(User *)value;
- (void)addHasUsers:(NSSet *)values;
- (void)removeHasUsers:(NSSet *)values;

@end
