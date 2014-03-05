//
//  User+Create.m
//  ypom
//
//  Created by Christoph Krey on 27.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "User+Create.h"
#include "base32.h"
#include "sodium.h"

@implementation User (Create)
+ (User *)userWithPk:(NSData *)pk
                    name:(NSString *)name
inManagedObjectContext:(NSManagedObjectContext *)context
{
    User *user = [User existsUserWithPk:pk inManagedObjectContext:context];
    
    if (!user) {
        
        user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
        
        user.pk = pk;
        user.name = name;
    }
    
    return user;
}

+ (User *)userWithBase32EncodedPk:(NSString *)pk32
                             name:(NSString *)name
           inManagedObjectContext:(NSManagedObjectContext *)context
{
    unsigned char pk[UNBASE32_LEN(BASE32_LEN(crypto_box_PUBLICKEYBYTES))];
    base32_decode((unsigned char *)[pk32 UTF8String], pk);
    
    return [User userWithPk:[[NSData alloc] initWithBytes:pk length:crypto_box_PUBLICKEYBYTES]
                       name:name inManagedObjectContext:context];
}

+ (User *)existsUserWithPk:(NSData *)pk
    inManagedObjectContext:(NSManagedObjectContext *)context
{
    User *user = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    request.predicate = [NSPredicate predicateWithFormat:@"pk = %@", pk];
    
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

+ (User *)existsUserWithBase32EncodedPk:(NSString *)pk32
                 inManagedObjectContext:(NSManagedObjectContext *)context
{
    unsigned char pk[UNBASE32_LEN(BASE32_LEN(crypto_box_PUBLICKEYBYTES))];
    base32_decode((unsigned char *)[pk32 UTF8String], pk);
    
    return [User existsUserWithPk:[[NSData alloc] initWithBytes:pk length:crypto_box_PUBLICKEYBYTES]
           inManagedObjectContext:context];
}

- (NSComparisonResult)compare:(User *)user
{
    return [[self base32EncodedPk] compare:[user base32EncodedPk]];
}

- (NSString *)base32EncodedPk
{
    unsigned char pk32[BASE32_LEN(crypto_box_PUBLICKEYBYTES) + 1];
    base32_encode(self.pk.bytes, crypto_box_PUBLICKEYBYTES, pk32);
    pk32[sizeof(pk32) - 1] = 0;
    
    return [NSString stringWithUTF8String:(char *)pk32];
}

@end
