//
//  YPOM.m
//  ypom
//
//  Created by Christoph Krey on 26.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOM.h"
#import "tweetnacl.h"

@interface YPOM ()
@end

#define LEN 256

@implementation YPOM

- (id)init
{
    self = [super init];
    
    unsigned char n[crypto_box_NONCEBYTES];
    for (unsigned long long i = 0; i < crypto_box_NONCEBYTES; i++){
        n[i] = 0;
    }
    _n = [[NSData alloc] initWithBytes:n length:crypto_box_NONCEBYTES];
    
    return self;
}

- (void)createKeyPair
{
    unsigned char pk[crypto_box_PUBLICKEYBYTES];
    unsigned char sk[crypto_box_SECRETKEYBYTES];
    
    crypto_box_keypair(pk,sk);
    
    self.pk = [NSData dataWithBytes:pk length:crypto_box_PUBLICKEYBYTES];
    self.sk = [NSData dataWithBytes:sk length:crypto_box_SECRETKEYBYTES];
}

- (NSData *)box:(NSData *)message
{
    unsigned char m[LEN];
    unsigned char c[LEN];
    
    for (unsigned long long i = 0; i < crypto_box_ZEROBYTES; i++) {
        m[i] = 0;
    }
    memcpy(m + crypto_box_ZEROBYTES, message.bytes, message.length);
    crypto_box(c, m, crypto_box_ZEROBYTES + message.length, self.n.bytes, self.pk.bytes, self.sk.bytes);
    
    return [NSData dataWithBytes:c length:crypto_box_ZEROBYTES + message.length];
}

- (NSData *)boxOpen:(NSData *)cipher
{
    unsigned char m[LEN];
    unsigned char c[LEN];
    
    memcpy(c, cipher.bytes, cipher.length);
    if (crypto_box_open(m, c, cipher.length, self.n.bytes, self.pk.bytes, self.sk.bytes)) {
        return nil;
    } else {
        return [NSData dataWithBytes:m + crypto_box_ZEROBYTES length:cipher.length - crypto_box_ZEROBYTES];
    }
}

@end
