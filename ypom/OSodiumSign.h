//
//  OSodiumSign.h
//  ypom
//
//  Created by Christoph Krey on 15.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "OSodium.h"

@interface OSodiumSign : OSodium
@property (strong, nonatomic) NSData *secret;
@property (strong, nonatomic) NSData *verkey;
@property (strong, nonatomic) NSData *sigkey;

+ (OSodiumSign *)signFromData:(NSData *)data verkey:(NSData *)verkey;
- (NSData *)signOnWire;
- (void)createKeyPair;


@end
