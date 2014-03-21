//
//  YPOMInvitation.h
//  ypom
//
//  Created by Christoph Krey on 21.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YPOMInvitation : NSObject <UIAlertViewDelegate>
@property (strong, nonatomic) NSDictionary *group;
- (void)show;
@end
