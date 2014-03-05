//
//  NSString+stringWithData.m
//  ypom
//
//  Created by Christoph Krey on 05.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "NSString+stringWithData.h"

@implementation NSString (stringWithData)
+ (NSString *)stringWithData:(NSData *)data
{
    NSString *string = [[NSString alloc] init];
    
    for (int i = 0; i < data.length; i++) {
        char c;
        [data getBytes:&c range:NSMakeRange(i, 1)];
        string = [string stringByAppendingFormat:@"%c", c];
    }
    return string;
}

@end
