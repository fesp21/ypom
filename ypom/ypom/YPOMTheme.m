//
//  YPOMTheme.m
//  ypom
//
//  Created by Christoph Krey on 12.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOMTheme.h"
@interface YPOMTheme ()
@property (strong, nonatomic) NSDictionary *root;

@end

@implementation YPOMTheme

- (id)init
{
    self = [super init];
    if (self) {
        _backgroundColor = [UIColor whiteColor];
        _barColor = [UIColor whiteColor];
        _textColor = [UIColor blackColor];
        
        _onlineColor = [UIColor greenColor];
        _offlineColor = [UIColor redColor];
        _unknownColor = [UIColor blackColor];
        
        _myColor = [UIColor purpleColor];
        _yourColor = [UIColor blueColor];
        
        _messageTextAttributes = @{};

        NSURL *url = [NSBundle.mainBundle URLForResource:@"YPOMThemes"
                                           withExtension:@"plist"];
        _root = [NSDictionary dictionaryWithContentsOfFile:url.path];
        NSString *fileDefaultName = _root[@"defaultTheme"];
        self.selected = fileDefaultName;
    }
    return self;
}

- (void)setSelected:(NSString *)selected
{
    NSDictionary *fileThemes = self.root[@"themes"];
    if (fileThemes && [fileThemes isKindOfClass:[NSDictionary class]]) {
        NSDictionary *fileTheme = fileThemes[selected];
        if (fileTheme && [fileTheme isKindOfClass:[NSDictionary class]]) {
            _backgroundColor = [self colorFromDictionary:fileTheme[@"backgroundColor"]];
            _barColor = [self colorFromDictionary:fileTheme[@"barColor"]];
            _textColor = [self colorFromDictionary:fileTheme[@"textColor"]];
            _onlineColor = [self colorFromDictionary:fileTheme[@"onlineColor"]];
            _offlineColor = [self colorFromDictionary:fileTheme[@"offlineColor"]];
            _unknownColor = [self colorFromDictionary:fileTheme[@"unknownColor"]];
            _myColor = [self colorFromDictionary:fileTheme[@"myColor"]];
            _yourColor = [self colorFromDictionary:fileTheme[@"yourColor"]];
            _messageTextAttributes = fileTheme[@"messageTextAttributes"];
            
            _selected = selected;
        }
    }
}

- (UIColor *)colorFromDictionary:(NSDictionary *)color
{
    CGFloat red = [color[@"red"] intValue] / 255.0;
    CGFloat green = [color[@"green"] intValue] / 255.0;
    CGFloat blue = [color[@"blue"] intValue] / 255.0;
    CGFloat alpha = [color[@"alpha"] doubleValue];
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
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

@end
