//
//  YPOMThemes.m
//  ypom
//
//  Created by Christoph Krey on 18.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOMThemes.h"

@interface YPOMThemes ()
@property (strong, nonatomic) NSDictionary *root;
@property (strong, nonatomic) NSString *selected;
@end

@implementation YPOMThemes
- (id)init
{
    self = [super init];
    if (self) {
        NSURL *url = [NSBundle.mainBundle URLForResource:@"YPOMThemes"
                                           withExtension:@"plist"];
        _root = [NSDictionary dictionaryWithContentsOfFile:url.path];
    }
    return self;
}

- (NSUInteger)numberOfThemes
{
    return [self.root[@"themes"] count];
}

- (NSString *)nameOfThemeNumber:(NSUInteger)n
{
    NSDictionary *themes = self.root[@"themes"];
    NSArray *array = [[themes allKeys] sortedArrayUsingSelector:@selector(compare:)];
    return array[n];
}

- (YPOMTheme *)selectTheme:(NSString *)name
{
    YPOMTheme *theme = [[YPOMTheme alloc] init];
    
    NSDictionary *fileThemes = self.root[@"themes"];
    if (fileThemes && [fileThemes isKindOfClass:[NSDictionary class]]) {
        NSDictionary *fileTheme = fileThemes[name];
        if (fileTheme && [fileTheme isKindOfClass:[NSDictionary class]]) {
            theme.name = name;
            theme.backgroundColor = [self colorFromDictionary:fileTheme[@"backgroundColor"]];
            theme.barColor = [self colorFromDictionary:fileTheme[@"barColor"]];
            theme.textColor = [self colorFromDictionary:fileTheme[@"textColor"]];
            theme.onlineColor = [self colorFromDictionary:fileTheme[@"onlineColor"]];
            theme.offlineColor = [self colorFromDictionary:fileTheme[@"offlineColor"]];
            theme.unknownColor = [self colorFromDictionary:fileTheme[@"unknownColor"]];
            theme.myColor = [self colorFromDictionary:fileTheme[@"myColor"]];
            theme.yourColor = [self colorFromDictionary:fileTheme[@"yourColor"]];
            theme.messageTextAttributes = fileTheme[@"messageTextAttributes"];            
        }
    }
    return theme;
}

- (UIColor *)colorFromDictionary:(NSDictionary *)color
{
    CGFloat red = [color[@"red"] intValue] / 255.0;
    CGFloat green = [color[@"green"] intValue] / 255.0;
    CGFloat blue = [color[@"blue"] intValue] / 255.0;
    CGFloat alpha = [color[@"alpha"] doubleValue];
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end
