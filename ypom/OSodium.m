//
//  OSodium.m
//  ypom
//
//  Created by Christoph Krey on 15.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "OSodium.h"
#import <sodium.h>

static OSodium *theOSodium;

@implementation OSodium

- (id)init {
    if (!theOSodium) {
        self = [super init];
        theOSodium = self;
        sodium_init();
    }
    return self;
}

+ (OSodium *)theOSodium
{
    if (!theOSodium) {
        theOSodium = [[OSodium alloc] init];
    }
    return theOSodium;
}


@end
