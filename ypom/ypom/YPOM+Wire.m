//
//  YPOM+Wire.m
//  ypom
//
//  Created by Christoph Krey on 05.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOM+Wire.h"

@implementation YPOM (Wire)
+ (YPOM *)ypomFromWire:(NSData *)wireData pk:(NSData *)pk sk:(NSData *)sk
{
    YPOM *ypom = [[YPOM alloc] init];
    ypom.pk = pk;
    ypom.sk = sk;
    
    int i;
    
    for (i = 0; i < wireData.length; i++) {
        char c;
        [wireData getBytes:&c range:NSMakeRange(i, 1)];
        if (c == ':') {
            break;
        }
    }
    
    if (i < wireData.length) {
        NSData *nonce = [NSData dataWithBytes:wireData.bytes length:i];
        
        ypom.nonce = [[NSData alloc] initWithBase64EncodedData:nonce options:0];
        
        NSData *cipher = [NSData dataWithBytes:wireData.bytes + i + 1 length:wireData.length - i - 1];
        
        NSData *ypomCipher = [[NSData alloc] initWithBase64EncodedData:cipher options:0];
        ypom.message = [ypom boxOpen:ypomCipher];
    }

    return ypom;
}

- (NSData *)wireData
{
    NSMutableData *wireData = [[NSMutableData alloc] init];
    [wireData appendData:[self.nonce base64EncodedDataWithOptions:0]];
    char c = ':';
    [wireData appendBytes:&c length:1];
    [wireData appendData:[self.cipher base64EncodedDataWithOptions:0]];
    return wireData;
}
@end
