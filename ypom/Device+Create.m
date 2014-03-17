//
//  Device+Create.m
//  ypom
//
//  Created by Christoph Krey on 15.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "Device+Create.h"

@implementation Device (Create)
+ (Device *)deviceWithToken:(NSData *)token belongsTo:(User *)belongsTo
{
    Device *device = [Device existsDeviceWithToken:token belongsTo:belongsTo];
    if (!device) {
        device = [NSEntityDescription insertNewObjectForEntityForName:@"Device"
                                               inManagedObjectContext:belongsTo.managedObjectContext];
    }
    device.deviceToken = token;
    device.online = nil;
    device.identifier = nil;
    device.belongsTo = belongsTo;
    return device;
}

+ (Device *)existsDeviceWithToken:(NSData *)token belongsTo:(User *)belongsTo
{
    Device *device = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Device"];
    request.predicate = [NSPredicate predicateWithFormat:@"deviceToken = %@ AND belongsTo = %@", token, belongsTo];
    
    NSError *error = nil;
    
    NSArray *matches = [belongsTo.managedObjectContext executeFetchRequest:request error:&error];
    
    if (!matches) {
        // handle error
    } else {
        if ([matches count]) {
            device = [matches lastObject];
        }
    }
    
    return device;
}

@end
