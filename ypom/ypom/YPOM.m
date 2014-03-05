//
//  YPOM.m
//  ypom
//
//  Created by Christoph Krey on 26.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOM.h"
//#import "tweetnacl.h"
#import "sodium.h"

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
    _nonce = [[NSData alloc] initWithBytes:n length:crypto_box_NONCEBYTES];
    
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
    self.message = message;

    return self.cipher;
}

- (NSData *)boxOpen:(NSData *)cipher
{
    unsigned char m[LEN];
    unsigned char c[LEN];
    unsigned char p[crypto_box_PUBLICKEYBYTES];
    unsigned char s[crypto_box_SECRETKEYBYTES];
    unsigned char n[crypto_box_NONCEBYTES];
    
    NSLog(@"ypom.pk:%@", self.pk);
    NSLog(@"ypom.sk:%@", self.sk);
    NSLog(@"ypom.nonce:%@", self.nonce);
    NSLog(@"ypom.cipher:%@", cipher);
    
    for (unsigned long long i = 0; i < crypto_box_BOXZEROBYTES; i++) {
        c[i] = 0;
    }

    memcpy(c + crypto_box_BOXZEROBYTES, cipher.bytes, cipher.length);
    memcpy(p, self.pk.bytes, crypto_box_PUBLICKEYBYTES);
    memcpy(s, self.sk.bytes, crypto_box_SECRETKEYBYTES);
    memcpy(n, self.nonce.bytes, crypto_box_NONCEBYTES);

    if (crypto_box_open(m, c, crypto_box_BOXZEROBYTES + cipher.length, n, p, s)) {
        self.message = nil;
    } else {
        self.message = [NSData dataWithBytes:m + crypto_box_ZEROBYTES
                                         length:cipher.length + crypto_box_BOXZEROBYTES - crypto_box_ZEROBYTES];
        NSLog(@"ypom.message:%@", self.message);
    }
    return self.message;
}

- (NSData *)cipher
{
    unsigned char m[LEN];
    unsigned char c[LEN];
    unsigned char p[crypto_box_PUBLICKEYBYTES];
    unsigned char s[crypto_box_SECRETKEYBYTES];
    unsigned char n[crypto_box_NONCEBYTES];
    
    NSLog(@"ypom.p:%@", self.pk);
    NSLog(@"ypom.s:%@", self.sk);
    NSLog(@"ypom.nonce:%@", self.nonce);
    NSLog(@"ypom.message:%@", self.message);
    
    for (unsigned long long i = 0; i < crypto_box_ZEROBYTES; i++) {
        m[i] = 0;
    }
    memcpy(m + crypto_box_ZEROBYTES, self.message.bytes, self.message.length);
    memcpy(p, self.pk.bytes, crypto_box_PUBLICKEYBYTES);
    memcpy(s, self.sk.bytes, crypto_box_SECRETKEYBYTES);
    memcpy(n, self.nonce.bytes, crypto_box_NONCEBYTES);
    
    crypto_box(c, m, crypto_box_ZEROBYTES + self.message.length, n, p, s);
    
    NSData *cipher = [NSData dataWithBytes:c + crypto_box_BOXZEROBYTES
                                    length:self.message.length + crypto_box_ZEROBYTES - crypto_box_BOXZEROBYTES];
    NSLog(@"ypom.cipher:%@", cipher);
    
    return cipher;
}

@end
