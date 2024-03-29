//
//  User+Create.m
//  ypom
//
//  Created by Christoph Krey on 27.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "User+Create.h"
#import "Group+Create.h"
#import "Message+Create.h"
#import "base32.h"
#import "sodium.h"
#import "OSodiumBox.h"
#import "OSodiumSign.h"
#import <AddressBook/AddressBook.h>

#define IDENTIFIER_LEN 5

@implementation User (Create)

+ (User *)newUserInManageObjectContext:(NSManagedObjectContext *)context
{
    OSodiumBox *box = [[OSodiumBox alloc] init];
    [box createKeyPair];
    
    unsigned char h[crypto_hash_sha256_BYTES];
    crypto_hash_sha256(h, box.pubkey.bytes, box.pubkey.length);
    
    unsigned char pk32[BASE32_LEN(IDENTIFIER_LEN) + 1];
    base32_encode(h, BASE32_LEN(IDENTIFIER_LEN), pk32);
    pk32[BASE32_LEN(IDENTIFIER_LEN)] = 0;
    
    NSString *identifier = [NSString stringWithUTF8String:(char *)pk32];

    User *user = [User userWithIdentifier:identifier inManagedObjectContext:context];
    
    user.pubkey = box.pubkey;
    user.seckey = box.seckey;
    
    OSodiumSign *sign = [[OSodiumSign alloc] init];
    [sign createKeyPair];
    
    user.verkey = sign.verkey;
    user.sigkey = sign.sigkey;
    
    return user;
}

+ (User *)existsUserWithIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)context
{
    User *user = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier = %@", identifier];
    
    NSError *error = nil;
    
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches) {
        // handle error
    } else {
        if ([matches count]) {
            user = [matches lastObject];
        }
    }
    
    return user;
}

+ (User *)userWithIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)context
{
    User *user = [User existsUserWithIdentifier:identifier inManagedObjectContext:context];
    
    if (!user) {
        
        user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
        
        user.identifier = identifier;
    }
    
    return user;
}

- (NSString *)name
{
    NSString *name;
    
    ABRecordID rid = self.abRecordId ? [self.abRecordId intValue] : kABRecordInvalidID;
    if (rid && rid != kABRecordInvalidID) {
        CFErrorRef myError = NULL;
        ABAddressBookRef abref = ABAddressBookCreateWithOptions(NULL, &myError);
        if (abref) {
            ABRecordRef rref = ABAddressBookGetPersonWithRecordID(abref, rid);
            name = CFBridgingRelease(ABRecordCopyCompositeName(rref));
            CFRelease(abref);
        }
    }
    return name;
}

- (NSString *)displayName
{
    NSString *name = [self name];
    return name ? name : [NSString stringWithFormat:@"#%@", self.identifier];
}


- (unsigned long)numberOfUnseenMessages
{
    unsigned long u = 0;
    
    for (Message *message in self.hasMessages) {
        if (message.outgoing && ![message.outgoing boolValue]) {
            if (message.seen && ![message.seen boolValue]) {
                u++;
            }
        }
    }
    return u;
}

- (NSData *)imageData
{
    NSData *imageData = nil;
    ABRecordID rid = self.abRecordId ? [self.abRecordId intValue] : kABRecordInvalidID;
    if (rid && rid != kABRecordInvalidID) {
        CFErrorRef myError = NULL;
        ABAddressBookRef abref = ABAddressBookCreateWithOptions(NULL, &myError);
        if (abref) {
            ABRecordRef rref = ABAddressBookGetPersonWithRecordID(abref, rid);
            if (ABPersonHasImageData(rref)) {
                CFDataRef ir = ABPersonCopyImageDataWithFormat(rref, kABPersonImageFormatThumbnail);
                imageData = CFBridgingRelease(ir);
            }
            CFRelease(abref);
        }
    }
    return imageData;
}


@end
