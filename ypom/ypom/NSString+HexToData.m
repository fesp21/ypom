//
//  NSString+HexData.m
//  ypom
//
//  Created by Christoph Krey on 05.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "NSString+HexToData.h"

@implementation NSString (HexToData)
- (NSData *)hexToData {
    NSMutableData* data = [NSMutableData data];
    int idx;
    for (idx = 0; idx+2 <= self.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [self substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

@end
