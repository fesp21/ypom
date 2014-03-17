//
//  Device+Create.h
//  ypom
//
//  Created by Christoph Krey on 15.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "Device.h"
#import "User+Create.h"

@interface Device (Create)
+ (Device *)deviceWithToken:(NSData *)token belongsTo:(User *)belongsTo;
+ (Device *)existsDeviceWithToken:(NSData *)token belongsTo:(User *)belongsTo;

@end
