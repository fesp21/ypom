//
//  User+Create.h
//  ypom
//
//  Created by Christoph Krey on 27.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "User.h"
#import "Broker+Create.h"

@interface User (Create)
+ (User *)userWithIdentifier:(NSString *)identifier
inManagedObjectContext:(NSManagedObjectContext *)context;

+ (User *)existsUserWithIdentifier:(NSString *)identifier
      inManagedObjectContext:(NSManagedObjectContext *)context;

+ (User *)newUserInManageObjectContext:(NSManagedObjectContext *)context;

- (NSString *)displayName;
- (unsigned long)numberOfUnseenMessages;

@end
