//
//  OSodiumSecretBox.h
//  ypom
//
//  Created by Christoph Krey on 15.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "OSodium.h"

@interface OSodiumSecretBox : OSodium
@property (strong, nonatomic) NSData *secret;
@property (strong, nonatomic) NSData *phrase;

+ (OSodiumSecretBox *)secretBoxFromData:(NSData *)data phrase:(NSData *)phrase;
- (NSData *)secretBoxOnWire;

@end
