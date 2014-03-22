//
//  Group+Create.h
//  ypom
//
//  Created by Christoph Krey on 21.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "Group.h"
#import "User+Create.h"

@interface Group (Create)
+ (Group *)groupWithIdentifier:(NSString *)identifier
                     belongsTo:(User *)belongsTo
              inManagedObjectContext:(NSManagedObjectContext *)context;

+ (Group *)existsGroupWithIdentifier:(NSString *)identifier
              inManagedObjectContext:(NSManagedObjectContext *)context;

+ (Group *)newGroupInManageObjectContext:(NSManagedObjectContext *)context
                               belongsTo:(User *)belongsTo;

- (void)addUser:(User *)user;
- (void)removeUser:(User *)user;
- (NSString *)displayName;


@end
