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
    Broker *broker = [Broker existsBrokerWithHost:host port:port inManagedObjectContext:context];
    
    if (!broker) {
        
        broker = [NSEntityDescription insertNewObjectForEntityForName:@"Broker" inManagedObjectContext:context];
        
        broker.host = host;
        broker.port = @(port);
        broker.tls = @(tls);
        broker.auth = @(auth);
        broker.user = user;
        broker.passwd = password;
    }
    
    return broker;
}

+ (Broker *)existsBrokerWithHost:(NSString *)host
                             port:(UInt16)port
           inManagedObjectContext:(NSManagedObjectContext *)context
{
    Broker *broker = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Broker"];
    request.predicate = [NSPredicate predicateWithFormat:@"host = %@ AND port = %@", host, @(port)];
    
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

- (NSComparisonResult)compare:(Broker *)broker
{
    NSComparisonResult r = [self.host compare:broker.host];
    if (r == NSOrderedSame) {
        return [self.port compare:broker.port];
    }
    return r;

}

- (NSString *)url
{
    return [NSString stringWithFormat:@"%@", self.host];
}


@end
