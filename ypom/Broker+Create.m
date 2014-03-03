//
//  Broker+Create.m
//  ypom
//
//  Created by Christoph Krey on 27.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "Broker+Create.h"

@implementation Broker (Create)
+ (Broker *)brokerWithHost:(NSString *)host
                      port:(UInt16)port
                       tls:(BOOL)tls
                      auth:(BOOL)auth
                      user:(NSString *)user
                  password:(NSString *)password
    inManagedObjectContext:(NSManagedObjectContext *)context
{
    Broker *broker = [Broker existsBroker:context];
    
    if (!broker) {
        
        broker = [NSEntityDescription insertNewObjectForEntityForName:@"Broker" inManagedObjectContext:context];
        
    }
    broker.host = host;
    broker.port = @(port);
    broker.tls = @(tls);
    broker.auth = @(auth);
    broker.user = user;
    broker.passwd = password;
    
    return broker;
}

+ (Broker *)existsBroker:(NSManagedObjectContext *)context
{
    Broker *broker = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Broker"];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches) {
        // handle error
    } else {
        if ([matches count]) {
            broker = [matches lastObject];
        }
    }
    
    return broker;
}


@end
