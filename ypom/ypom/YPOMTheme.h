//
//  YPOMTheme.h
//  ypom
//
//  Created by Christoph Krey on 12.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YPOMTheme : NSObject

@property (strong, nonatomic) UIColor *backgroundColor;
@property (strong, nonatomic) UIColor *barColor;
@property (strong, nonatomic) UIColor *textColor;
@property (strong, nonatomic) UIColor *onlineColor;
@property (strong, nonatomic) UIColor *offlineColor;
@property (strong, nonatomic) UIColor *unknownColor;
@property (strong, nonatomic) UIColor *myColor;
@property (strong, nonatomic) UIColor *yourColor;
@property (strong, nonatomic) NSDictionary *messageTextAttributes;


@end
