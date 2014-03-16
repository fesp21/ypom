//
//  OSodiumBox.m
//  ypom
//
//  Created by Christoph Krey on 15.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "OSodiumBox.h"
#import "OSodium.h"
#import <sodium.h>

@implementation OSodiumBox
+ (OSodiumBox *)boxFromData:(NSData *)data pubkey:(NSData *)pubkey seckey:(NSData *)seckey
{
    OSodiumBox *box;
    
    unsigned char p[crypto_box_PUBLICKEYBYTES];
    unsigned char s[crypto_box_SECRETKEYBYTES];
    unsigned char n[crypto_box_NONCEBYTES];
    
    memcpy(p, pubkey.bytes, crypto_box_PUBLICKEYBYTES);
    memcpy(s, seckey.bytes, crypto_box_SECRETKEYBYTES);
    memcpy(n, data.bytes, crypto_box_NONCEBYTES);

    unsigned char *c;
    _sodium_alignedcalloc(&c, crypto_box_BOXZEROBYTES + data.length - crypto_box_NONCEBYTES);
    
    if (c) {
        sodium_memzero(c, crypto_box_BOXZEROBYTES);
        memcpy(c + crypto_box_BOXZEROBYTES, data.bytes + crypto_box_NONCEBYTES, data.length - crypto_box_NONCEBYTES);
        
        unsigned char *m;
        _sodium_alignedcalloc(&m, crypto_box_ZEROBYTES + data.length);
        
        if (m) {
            if (!crypto_box_open(m, c, crypto_box_BOXZEROBYTES + data.length - crypto_box_NONCEBYTES, n, p, s)) {
                box = [[OSodiumBox alloc] init];
                box.pubkey = [NSData dataWithBytes:p length:crypto_box_PUBLICKEYBYTES];
                box.seckey = [NSData dataWithBytes:s length:crypto_box_SECRETKEYBYTES];
                box.secret = [NSData dataWithBytes:m + crypto_box_ZEROBYTES
                                            length:data.length - crypto_box_NONCEBYTES + crypto_box_BOXZEROBYTES - crypto_box_ZEROBYTES];
            }
            free(m);
        }
        free(c);
    }
    return box;
}

- (NSData *)boxOnWire
{
    NSMutableData *data;

    unsigned char n[crypto_box_NONCEBYTES];
    randombytes(n, crypto_box_NONCEBYTES);
    
    unsigned char p[crypto_box_PUBLICKEYBYTES];
    unsigned char s[crypto_box_SECRETKEYBYTES];
    
    memcpy(p, self.pubkey.bytes, crypto_box_PUBLICKEYBYTES);
    memcpy(s, self.seckey.bytes, crypto_box_SECRETKEYBYTES);

    unsigned char *m;
    _sodium_alignedcalloc(&m, crypto_box_ZEROBYTES + self.secret.length);
    
    if (m) {
        sodium_memzero(m, crypto_box_ZEROBYTES);
        memcpy(m + crypto_box_ZEROBYTES, self.secret.bytes, self.secret.length);

        unsigned char *c;
        _sodium_alignedcalloc(&c, crypto_box_BOXZEROBYTES + self.secret.length);
        
        if (c) {
            crypto_box(c, m, crypto_box_ZEROBYTES + self.secret.length, n, p, s);
            
            data = [[NSData dataWithBytes:n length:crypto_box_NONCEBYTES] mutableCopy];
            [data appendBytes:c + crypto_box_BOXZEROBYTES
                       length:self.secret.length + crypto_box_ZEROBYTES - crypto_box_BOXZEROBYTES];
            free(c);
        }
        free(m);
    }
    return data;
}

- (void)createKeyPair
{
    unsigned char p[crypto_box_PUBLICKEYBYTES];
    unsigned char s[crypto_box_SECRETKEYBYTES];
    
    crypto_box_keypair(p, s);
    
    self.pubkey = [NSData dataWithBytes:p length:crypto_box_PUBLICKEYBYTES];
    self.seckey = [NSData dataWithBytes:s length:crypto_box_SECRETKEYBYTES];
}

@end
