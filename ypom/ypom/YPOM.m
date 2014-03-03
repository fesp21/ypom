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

#define LEN 512
void randombytes(unsigned char *ptr, unsigned long long length);

@implementation YPOM

- (id)init
{
    self = [super init];
    
    unsigned char n[crypto_box_NONCEBYTES];
    randombytes(n, crypto_box_NONCEBYTES);
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
    unsigned char p[crypto_box_PUBLICKEYBYTES];
    unsigned char s[crypto_box_SECRETKEYBYTES];
    unsigned char n[crypto_box_NONCEBYTES];
    
    NSLog(@"ypom p:%@", self.pk);
    NSLog(@"ypom s:%@", self.sk);
    NSLog(@"ypom n:%@", self.n);
    NSLog(@"ypom m:%@", message);
    
    for (unsigned long long i = 0; i < crypto_box_ZEROBYTES; i++) {
        m[i] = 0;
    }
    memcpy(m + crypto_box_ZEROBYTES, message.bytes, message.length);
    memcpy(p, self.pk.bytes, crypto_box_PUBLICKEYBYTES);
    memcpy(s, self.sk.bytes, crypto_box_SECRETKEYBYTES);
    memcpy(n, self.n.bytes, crypto_box_NONCEBYTES);
    
    crypto_box(c, m, crypto_box_ZEROBYTES + message.length, n, p, s);
    
    NSData *cipher = [NSData dataWithBytes:c + crypto_box_BOXZEROBYTES
                                    length:message.length + crypto_box_ZEROBYTES - crypto_box_BOXZEROBYTES];
    NSLog(@"ypom c:%@", cipher);
    
    return cipher;
}

- (NSData *)boxOpen:(NSData *)cipher
{
    unsigned char m[LEN];
    unsigned char c[LEN];
    unsigned char p[crypto_box_PUBLICKEYBYTES];
    unsigned char s[crypto_box_SECRETKEYBYTES];
    unsigned char n[crypto_box_NONCEBYTES];
    
    NSLog(@"ypom p:%@", self.pk);
    NSLog(@"ypom s:%@", self.sk);
    NSLog(@"ypom n:%@", self.n);
    NSLog(@"ypom c:%@", cipher);
    
    for (unsigned long long i = 0; i < crypto_box_BOXZEROBYTES; i++) {
        c[i] = 0;
    }

    memcpy(c + crypto_box_BOXZEROBYTES, cipher.bytes, cipher.length);
    memcpy(p, self.pk.bytes, crypto_box_PUBLICKEYBYTES);
    memcpy(s, self.sk.bytes, crypto_box_SECRETKEYBYTES);
    memcpy(n, self.n.bytes, crypto_box_NONCEBYTES);

    if (crypto_box_open(m, c, crypto_box_BOXZEROBYTES + cipher.length, n, p, s)) {
        return nil;
    } else {
        NSData *message = [NSData dataWithBytes:m + crypto_box_ZEROBYTES
                                         length:cipher.length + crypto_box_BOXZEROBYTES - crypto_box_ZEROBYTES];
        NSLog(@"ypom m:%@", message);

        return message;
    }
}

@end
