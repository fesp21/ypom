//
//  YPOM+Wire.m
//  ypom
//
//  Created by Christoph Krey on 05.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOM+Wire.h"

@implementation YPOM (Wire)
+ (YPOM *)ypomFromWire:(NSString *)wireString pk:(NSData *)pk sk:(NSData *)sk
{
    YPOM *ypom = [[YPOM alloc] init];
    ypom.pk = pk;
    ypom.sk = sk;
    
    NSArray *arrayOfStrings = [wireString componentsSeparatedByString:@":"];
    
    ypom.nonce = [[NSData alloc] initWithBase64EncodedString:arrayOfStrings[0] options:0];
    
    NSData *cipher = [[NSData alloc] initWithBase64EncodedString:arrayOfStrings[1] options:0];
    ypom.message = [ypom boxOpen:cipher];

    return ypom;
}

- (NSString *)wireString
{
    return [NSString stringWithFormat:@"%@:%@",
            [self.nonce base64EncodedStringWithOptions:0],
            [self.cipher base64EncodedStringWithOptions:0]
            ];
}
@end
