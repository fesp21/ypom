//
//  User+Create.m
//  ypom
//
//  Created by Christoph Krey on 27.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "User+Create.h"

@implementation User (Create)
+ (User *)userWithName:(NSString *)name
                    pk:(NSData *)pk
                    sk:(NSData *)sk
                broker:(Broker *)broker
inManagedObjectContext:(NSManagedObjectContext *)context
{
    User *user = [User existsUserWithName:name broker:broker inManagedObjectContext:context];
    
    if (!user) {
        
        user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
        
        user.name = name;
        user.pk = pk;
        user.sk = sk;
        user.belongsTo = broker;
    }
    
    return user;
}

+ (User *)existsUserWithName:(NSString *)name
                      broker:(Broker *)broker
      inManagedObjectContext:(NSManagedObjectContext *)context
{
    User *user = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    request.predicate = [NSPredicate predicateWithFormat:@"belongsTo = %@ AND name = %@", broker, name];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches) {
        // handle error
    } else {
        if ([matches count]) {
            user = [matches lastObject];
        }
    }
    
    return user;
}

- (NSComparisonResult)compare:(User *)user
{
    NSComparisonResult r = [self.belongsTo compare:user.belongsTo];
    if (r == NSOrderedSame) {
        return [self.name compare:user.name];
    }
    return r;
}

- (NSString *)url
{
    return [NSString stringWithFormat:@"%@:%@", self.belongsTo.url, self.belongsTo.port];
}


@end
