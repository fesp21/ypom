//
//  YPOMThemes.h
//  ypom
//
//  Created by Christoph Krey on 18.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YPOMTheme.h"

@interface YPOMThemes : NSObject
- (YPOMTheme *)selectTheme:(NSString *)name;
- (NSUInteger)numberOfThemes;
- (NSString *)nameOfThemeNumber:(NSUInteger)n;

@end
