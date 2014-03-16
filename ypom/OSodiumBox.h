//
//  OSodiumBox.h
//  ypom
//
//  Created by Christoph Krey on 15.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "OSodium.h"

@interface OSodiumBox : OSodium
@property (strong, nonatomic) NSData *secret;
@property (strong, nonatomic) NSData *pubkey;
@property (strong, nonatomic) NSData *seckey;

+ (OSodiumBox *)boxFromData:(NSData *)data pubkey:(NSData *)pubkey seckey:(NSData *)seckey;
- (NSData *)boxOnWire;
- (void)createKeyPair;

@end
