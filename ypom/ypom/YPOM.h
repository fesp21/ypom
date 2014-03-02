//
//  YPOM.h
//  ypom
//
//  Created by Christoph Krey on 26.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YPOM : NSObject
@property (strong, nonatomic) NSData *pk;
@property (strong, nonatomic) NSData *sk;
@property (strong, nonatomic) NSData *n;

- (void)createKeyPair;
- (NSData *)box:(NSData *)message;
- (NSData *)boxOpen:(NSData *)cipher;

@end
