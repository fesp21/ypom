//
//  YPOM.m
//  ypom
//
//  Created by Christoph Krey on 26.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOM.h"
#import "sodium.h"

@interface YPOM ()
@end

#undef USE_MALLOC
#ifndef USE_MALLOC
#define BUFFER_LEN 1024*1024*64
static unsigned char cp[BUFFER_LEN];
static unsigned char mp[BUFFER_LEN];
#endif

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
    NSLog(@"ypom.pk:%@", self.pk);
    NSLog(@"ypom.sk:%@", self.sk);
    NSLog(@"ypom.nonce:%@", self.nonce);
    NSLog(@"ypom.cipher:%@...", [cipher subdataWithRange:NSMakeRange(0, MIN(16, cipher.length))]);
    self.message = nil;
    
    unsigned char p[crypto_box_PUBLICKEYBYTES];
    unsigned char s[crypto_box_SECRETKEYBYTES];
    unsigned char n[crypto_box_NONCEBYTES];
    
#ifdef USE_MALLOC
    unsigned char *cp = (unsigned char *)malloc(crypto_box_BOXZEROBYTES + cipher.length);
    unsigned char *mp = (unsigned char *)malloc(crypto_box_ZEROBYTES + cipher.length);
#endif
    
    if (cp != (unsigned char *)0 && mp != (unsigned char *)0) {
        
        for (unsigned long long i = 0; i < crypto_box_BOXZEROBYTES; i++) {
            cp[i] = 0;
        }
        
        memcpy(cp + crypto_box_BOXZEROBYTES, cipher.bytes, cipher.length);
        memcpy(p, self.pk.bytes, crypto_box_PUBLICKEYBYTES);
        memcpy(s, self.sk.bytes, crypto_box_SECRETKEYBYTES);
        memcpy(n, self.nonce.bytes, crypto_box_NONCEBYTES);
        
        if (!crypto_box_open(mp, cp, crypto_box_BOXZEROBYTES + cipher.length, n, p, s)) {
            self.message = [NSData dataWithBytes:mp + crypto_box_ZEROBYTES
                                          length:cipher.length + crypto_box_BOXZEROBYTES - crypto_box_ZEROBYTES];
            NSLog(@"ypom.message:%@...", [self.message subdataWithRange:NSMakeRange(0, MIN(16, self.message.length))]);
        }
    }
    
#ifdef USE_MALLOC
    if (mp != (unsigned char *)0) free(mp);
    if (cp != (unsigned char *)0) free(cp);
#endif
    
    return self.message;
}

- (NSData *)cipher
{    
    NSLog(@"ypom.pk:%@", self.pk);
    NSLog(@"ypom.sk:%@", self.sk);
    NSLog(@"ypom.nonce:%@", self.nonce);
    NSLog(@"ypom.message:%@...", [self.message subdataWithRange:NSMakeRange(0, MIN(16, self.message.length))]);

    NSData *cipher = nil;
    
    unsigned char p[crypto_box_PUBLICKEYBYTES];
    unsigned char s[crypto_box_SECRETKEYBYTES];
    unsigned char n[crypto_box_NONCEBYTES];
    
#ifdef USE_MALLOC
    unsigned char *cp = (unsigned char *)malloc(crypto_box_BOXZEROBYTES + cipher.length);
    unsigned char *mp = (unsigned char *)malloc(crypto_box_ZEROBYTES + cipher.length);
#endif
    
    if (cp != (unsigned char *)0 && mp != (unsigned char *)0) {
        for (unsigned long long i = 0; i < crypto_box_ZEROBYTES; i++) {
            mp[i] = 0;
        }
        memcpy(mp + crypto_box_ZEROBYTES, self.message.bytes, self.message.length);
        memcpy(p, self.pk.bytes, crypto_box_PUBLICKEYBYTES);
        memcpy(s, self.sk.bytes, crypto_box_SECRETKEYBYTES);
        memcpy(n, self.nonce.bytes, crypto_box_NONCEBYTES);
        
        crypto_box(cp, mp, crypto_box_ZEROBYTES + self.message.length, n, p, s);
        
        cipher = [NSData dataWithBytes:cp + crypto_box_BOXZEROBYTES
                                length:self.message.length + crypto_box_ZEROBYTES - crypto_box_BOXZEROBYTES];
        NSLog(@"ypom.cipher:%@...", [cipher subdataWithRange:NSMakeRange(0, MIN(16, cipher.length))]);
    }
    
#ifdef USE_MALLOC
    if (mp != (unsigned char *)0) free(mp);
    if (cp != (unsigned char *)0) free(cp);
#endif
    
    return cipher;
}

@end
