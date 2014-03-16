//
//  OSodiumSign.m
//  ypom
//
//  Created by Christoph Krey on 15.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "OSodiumSign.h"
#import "OSodium.h"
#import <sodium.h>

@implementation OSodiumSign
+ (OSodiumSign *)signFromData:(NSData *)data verkey:(NSData *)verkey
{
    OSodiumSign *sign;
    
    unsigned char p[crypto_sign_PUBLICKEYBYTES];
    memcpy(p, verkey.bytes, crypto_sign_PUBLICKEYBYTES);
    
    unsigned char *sm;
    _sodium_alignedcalloc(&sm, data.length - crypto_sign_PUBLICKEYBYTES);
    
    if (sm) {
        memcpy(sm, data.bytes + crypto_sign_PUBLICKEYBYTES, data.length - crypto_sign_PUBLICKEYBYTES);
        
        unsigned char *m;
        _sodium_alignedcalloc(&m, data.length - crypto_sign_PUBLICKEYBYTES);
        
        unsigned long long mlen;
        
        if (m) {
            if (!crypto_sign_open(m, &mlen, sm, data.length - crypto_sign_PUBLICKEYBYTES, verkey.bytes)) {
                sign = [[OSodiumSign alloc] init];
                sign.verkey = [NSData dataWithBytes:p length:crypto_sign_PUBLICKEYBYTES];
                sign.secret = [NSData dataWithBytes:m length:mlen];
            }
            free(m);
        }
        free(sm);
    }
    return sign;
}

- (NSData *)signOnWire
{
    NSMutableData *data;
    
    unsigned char p[crypto_sign_PUBLICKEYBYTES];
    unsigned char s[crypto_sign_SECRETKEYBYTES];
    
    memcpy(p, self.verkey.bytes, crypto_sign_PUBLICKEYBYTES);
    memcpy(s, self.sigkey.bytes, crypto_sign_SECRETKEYBYTES);
    
    unsigned char *m;
    _sodium_alignedcalloc(&m, self.secret.length);
    
    if (m) {
        memcpy(m, self.secret.bytes, self.secret.length);
        
        unsigned char *sm;
        _sodium_alignedcalloc(&sm, self.secret.length + crypto_sign_BYTES);
        
        unsigned long long smlen;
        
        if (sm) {
            crypto_sign(sm, &smlen, m, self.secret.length, s);
            
            data = [[NSData dataWithBytes:p length:crypto_sign_PUBLICKEYBYTES] mutableCopy];
            [data appendBytes:sm length:smlen];
            free(sm);
        }
        free(m);
    }
    return data;
}

- (void)createKeyPair
{
    unsigned char p[crypto_sign_PUBLICKEYBYTES];
    unsigned char s[crypto_sign_SECRETKEYBYTES];
    
    crypto_sign_keypair(p,s);
    
    self.verkey = [NSData dataWithBytes:p length:crypto_sign_PUBLICKEYBYTES];
    self.sigkey = [NSData dataWithBytes:s length:crypto_sign_SECRETKEYBYTES];
}


@end
