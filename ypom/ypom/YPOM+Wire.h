//
//  YPOM+Wire.h
//  ypom
//
//  Created by Christoph Krey on 05.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOM.h"

@interface YPOM (Wire)
+ (YPOM *)ypomFromWire:(NSData *)wireData pk:(NSData *)pk sk:(NSData *)sk;
- (NSData *)wireData;
@end
