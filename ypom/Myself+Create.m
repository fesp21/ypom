//
//  Myself+Create.m
//  ypom
//
//  Created by Christoph Krey on 27.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "Myself+Create.h"

@implementation Myself (Create)
+ (Myself *)myselfWithUser:(User *)user
    inManagedObjectContext:(NSManagedObjectContext *)context
{
    Myself *myself = [Myself existsMyselfInManagedObjectContext:context];
    
    if (!myself) {
        
        myself = [NSEntityDescription insertNewObjectForEntityForName:@"Myself" inManagedObjectContext:context];
        
        myself.myUser = user;
    }
    
    return myself;
}

+ (Myself *)existsMyselfInManagedObjectContext:(NSManagedObjectContext *)context
{
    Myself *myself = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Myself"];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches) {
        // handle error
    } else {
        if ([matches count]) {
            myself = [matches lastObject];
        }
    }
    
    return myself;
}

@end
