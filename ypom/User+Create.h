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
+ (User *)userWithPk:(NSData *)pk
                name:(NSString *)name
inManagedObjectContext:(NSManagedObjectContext *)context;

+ (User *)userWithBase32EncodedPk:(NSString *)pk32
                name:(NSString *)name
inManagedObjectContext:(NSManagedObjectContext *)context;

+ (User *)existsUserWithPk:(NSData *)pk
      inManagedObjectContext:(NSManagedObjectContext *)context;

+ (User *)existsUserWithBase32EncodedPk:(NSString *)pk32
      inManagedObjectContext:(NSManagedObjectContext *)context;

- (NSComparisonResult)compare:(User *)user;

- (NSString *)base32EncodedPk;

@end
