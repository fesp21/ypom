//
//  Broker+Create.h
//  ypom
//
//  Created by Christoph Krey on 27.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "Broker.h"

@interface Broker (Create)
+ (Broker *)brokerWithHost:(NSString *)host
                      port:(UInt16)port
                       tls:(BOOL)tls
                      auth:(BOOL)auth
                      user:(NSString *)user
                  password:(NSString *)password
    inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Broker *)existsBrokerWithHost:(NSString *)host
                            port:(UInt16)port
          inManagedObjectContext:(NSManagedObjectContext *)context;

- (NSComparisonResult)compare:(Broker *)broker;

- (NSString *)url;

@end
