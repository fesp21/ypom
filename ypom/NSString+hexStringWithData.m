//
//  NSString+hexStringWithData.m
//  ypom
//
//  Created by Christoph Krey on 09.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "NSString+hexStringWithData.h"

@implementation NSString (hexStringWithData)
+ (NSString *)hexStringWithData:(NSData *)data
{
    NSString *string = [[NSString alloc] init];
    
    for (int i = 0; i < data.length; i++) {
        unsigned char c;
        [data getBytes:&c range:NSMakeRange(i, 1)];
        string = [string stringByAppendingString:[NSString stringWithFormat:@"%02x", c]];
    }
    return string;
}

@end
