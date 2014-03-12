//
//  YPOMTheme.m
//  ypom
//
//  Created by Christoph Krey on 12.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOMTheme.h"

@implementation YPOMTheme

- (id)init
{
    self = [super init];
    if (self) {
        _backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
        _barColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0];
        _textColor = [UIColor colorWithRed:148/255.0 green:150/255.0 blue:148/255.0 alpha:1.0];
        
        _onlineColor = [UIColor colorWithRed:57/255.0 green:235/255.0 blue:173/255.0 alpha:1.0];
        _offlineColor = [UIColor colorWithRed:255/255.0 green:73/255.0 blue:74/255.0 alpha:1.0];
        _unknownColor = [UIColor colorWithRed:165/255.0 green:142/255.0 blue:140/255.0 alpha:1.0];
        
        _myColor = [UIColor colorWithRed:255/255.0 green:203/255.0 blue:173/255.0 alpha:1.0];
        _yourColor = [UIColor colorWithRed:181/255.0 green:231/255.0 blue:247/255.0 alpha:1.0];
        
        _messageTextAttributes = @{};
    }
    return self;
}

@end
