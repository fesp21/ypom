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
+ (User *)userWithName:(NSString *)name
                    pk:(NSData *)pk
                    sk:(NSData *)sk
                broker:(Broker *)broker
inManagedObjectContext:(NSManagedObjectContext *)context;

+ (User *)existsUserWithName:(NSString *)name
                      broker:(Broker *)broker
      inManagedObjectContext:(NSManagedObjectContext *)context;

- (NSComparisonResult)compare:(User *)user;
- (NSString *)url;

@end
