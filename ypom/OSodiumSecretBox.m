//
//  OSodiumSecretBox.m
//  ypom
//
//  Created by Christoph Krey on 15.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "OSodiumSecretBox.h"
#import "OSodium.h"
#import <sodium.h>

@interface OSodiumSecretBox ()
@property (strong, nonatomic) NSData *key;

@end

@implementation OSodiumSecretBox
+ (OSodiumSecretBox *)secretBoxFromData:(NSData *)data phrase:(NSData *)phrase
{
    OSodiumSecretBox *secretBox;
    
    OSodiumSecretBox *box = [[OSodiumSecretBox alloc] init];
    box.phrase = phrase;
    
    if (box.key) {
        if (data && data.length > crypto_secretbox_NONCEBYTES) {
            unsigned char n[crypto_secretbox_NONCEBYTES];
            memcpy(n, data.bytes, crypto_secretbox_NONCEBYTES);
            
            unsigned char *c;
            _sodium_alignedcalloc(&c, data.length + crypto_secretbox_BOXZEROBYTES - crypto_secretbox_NONCEBYTES);
            if (c) {
                sodium_memzero(c, crypto_secretbox_BOXZEROBYTES);
                memcpy(c + crypto_secretbox_BOXZEROBYTES,
                       data.bytes + crypto_secretbox_NONCEBYTES,
                       data.length - crypto_secretbox_NONCEBYTES);
                
                unsigned char *m;
                _sodium_alignedcalloc(&m, data.length + crypto_secretbox_ZEROBYTES - crypto_secretbox_NONCEBYTES);
                if (m) {
                    if (!crypto_secretbox_open(m,
                                               c,
                                               crypto_secretbox_BOXZEROBYTES + data.length - crypto_secretbox_NONCEBYTES,
                                               n,
                                               box.key.bytes)) {
                        box.secret = [NSData dataWithBytes:m + crypto_secretbox_ZEROBYTES
                                                    length:data.length - crypto_secretbox_NONCEBYTES + crypto_secretbox_BOXZEROBYTES - crypto_secretbox_ZEROBYTES];
                        secretBox = box;
                    }
                    free(m);
                }
                free(c);
            }
            
        }
    }
    return secretBox;
}

- (NSData *)secretBoxOnWire
{
    NSMutableData *secretOnWire;
    
    if (self.secret && self.key) {
        unsigned char n[crypto_secretbox_NONCEBYTES];
        randombytes(n, crypto_secretbox_NONCEBYTES);

        unsigned char *m;
        _sodium_alignedcalloc(&m, self.secret.length + crypto_secretbox_ZEROBYTES);
        if (m) {
            sodium_memzero(m, crypto_secretbox_ZEROBYTES);
            memcpy(m + crypto_secretbox_ZEROBYTES, self.secret.bytes, self.secret.length);
            
            unsigned char *c;
            _sodium_alignedcalloc(&c, self.secret.length + crypto_secretbox_ZEROBYTES - crypto_secretbox_BOXZEROBYTES);
            if (c) {
                crypto_secretbox(c, m, crypto_secretbox_ZEROBYTES + self.secret.length, n, self.key.bytes);
                
                secretOnWire = [[NSData dataWithBytes:n length:crypto_secretbox_NONCEBYTES] mutableCopy];
                [secretOnWire appendData:[NSData dataWithBytes:c + crypto_secretbox_BOXZEROBYTES
                                                        length:self.secret.length + crypto_secretbox_ZEROBYTES - crypto_secretbox_BOXZEROBYTES]];
                free(c);
            }
            free(m);
        }
        
    }
    return secretOnWire;
}

- (void)setPhrase:(NSData *)phrase
{
    _phrase = phrase;
    if (phrase && phrase.length) {
        unsigned char h[crypto_hash_BYTES];
        crypto_hash_sha256(h, phrase.bytes, phrase.length);
        
        unsigned char k[crypto_secretbox_KEYBYTES];
        sodium_memzero(k, crypto_secretbox_KEYBYTES);
        memcpy(k, h, MIN(crypto_secretbox_KEYBYTES,crypto_hash_BYTES));
        
        self.key = [NSData dataWithBytes:k length:crypto_secretbox_KEYBYTES];
    } else {
        self.key = nil;
    }
}

@end
