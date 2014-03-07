//
//  YPOMSettingsTVC.m
//  ypom
//
//  Created by Christoph Krey on 01.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOMSettingsTVC.h"
#import "YPOMAppDelegate.h"
#import "Myself+Create.h"
#import "User+Create.h"
#import "Broker+Create.h"
#import "YPOM.h"
#include "sodium.h"
#import "NSString+stringWithData.h"
#define LEN 256


@interface YPOMSettingsTVC ()
@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *pk;
@property (weak, nonatomic) IBOutlet UITextField *sk;
@property (weak, nonatomic) IBOutlet UITextField *keyprotect;
@property (weak, nonatomic) IBOutlet UITextView *importexport;
@property (weak, nonatomic) IBOutlet UITextField *host;
@property (weak, nonatomic) IBOutlet UITextField *port;
@property (weak, nonatomic) IBOutlet UITextField *user;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UISwitch *tls;
@property (weak, nonatomic) IBOutlet UISwitch *auth;

@property (strong, nonatomic) User *oldUser;
@property (strong, nonatomic) NSString *oldHost;
@property (nonatomic) NSInteger oldPort;
@property (strong, nonatomic) NSString *oldUserID;
@property (strong, nonatomic) NSString *oldPasswd;
@property (nonatomic) BOOL oldTls;
@property (nonatomic) BOOL oldAuth;

@end

@implementation YPOMSettingsTVC

- (BOOL)disablesAutomaticKeyboardDismissal
{
    return NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.oldUser = delegate.myself.myUser;
    self.oldHost = delegate.broker.host;
    self.oldPort = [delegate.broker.port integerValue];
    self.oldUserID = delegate.broker.user;
    self.oldPasswd = delegate.broker.passwd;
    self.oldTls = [delegate.broker.tls boolValue];
    self.oldAuth = [delegate.broker.auth boolValue];
    
    [self changed];
}

- (void)viewWillDisappear:(BOOL)animated
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    if ([self.oldUser compare:delegate.myself.myUser] != NSOrderedSame) {
        [delegate unsubscribe:self.oldUser];
    }
    if (![self.oldHost isEqualToString:delegate.broker.host] ||
        self.oldPort != [delegate.broker.port integerValue] ||
        ![self.oldUserID isEqualToString:delegate.broker.user] ||
        ![self.oldPasswd isEqualToString:delegate.broker.passwd] ||
        self.oldTls != [delegate.broker.tls boolValue] ||
        self.oldAuth != [delegate.broker.auth boolValue]) {
        [delegate disconnect:nil];
        [delegate connect:nil];
    }
    if ([self.oldUser compare:delegate.myself.myUser] != NSOrderedSame) {
        [delegate subscribe:delegate.myself.myUser];
    }
    
    [delegate saveContext];
}

- (void)changed
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.name.text = delegate.myself.myUser.name;
    
    self.pk.text = [delegate.myself.myUser base32EncodedPk];
    self.sk.text = [delegate.myself.myUser.sk base64EncodedStringWithOptions:0];
    
    self.host.text = delegate.broker.host;
    self.port.text = [NSString stringWithFormat:@"%@", delegate.broker.port];
    self.tls.on = [delegate.broker.tls boolValue];
    
    self.auth.on = [delegate.broker.auth boolValue];
    self.user.text = delegate.broker.user;
    self.password.text = delegate.broker.passwd;
    
    // encrypt keys
    // setup encryption nonce from random
    unsigned char n[crypto_stream_NONCEBYTES];
    randombytes(n, crypto_stream_NONCEBYTES);
    // setup key by repeating key entry
    unsigned char k[crypto_stream_KEYBYTES];
    
    if (self.keyprotect.text.length) {
        for (long long i = 0; i < crypto_stream_KEYBYTES; i++) {
            k[i] = (unsigned char)[self.keyprotect.text characterAtIndex:i % self.keyprotect.text.length];
        }
        // now put the two keys in one string (already base64)
        NSString *string = [NSString stringWithFormat:@"%@:%@",
                            self.pk.text,
                            self.sk.text
                            ];
        NSLog(@"string: %@", string);
        
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        
        NSLog(@"data: %@", data);
        
        unsigned char m[LEN];
        unsigned char c[LEN];
        
        memcpy(m, data.bytes, data.length);
        
        crypto_stream_xor(c, m, data.length, n, k);
        
        self.importexport.text = [NSString stringWithFormat:@"%@:%@",
                                  [[NSData dataWithBytes:n length:crypto_stream_NONCEBYTES] base64EncodedStringWithOptions:0],
                                  [[NSData dataWithBytes:c length:data.length] base64EncodedStringWithOptions:0]
                                  ];
        NSLog(@"export: %@", self.importexport.text); } else {
            self.importexport.text = @"error: no keyprotection entered";
        }
}

- (IBAction)nameChanged:(UITextField *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.myself.myUser.name = sender.text;
    [self changed];
}

- (IBAction)loadPressed:(UIButton *)sender {
    
    NSArray *components = [self.importexport.text componentsSeparatedByString:@":"];
    if ([components count] == 2) {
        
        // setup decryption environment
        // get the nonce used
        unsigned char n[crypto_stream_NONCEBYTES];
        NSData *nonce = [[NSData alloc] initWithBase64EncodedString:components[0] options:0];
        memcpy(n, nonce.bytes, crypto_stream_NONCEBYTES);
        // build the key as in encryption
        unsigned char k[crypto_stream_KEYBYTES];
        for (long long i = 0; i < crypto_stream_KEYBYTES; i++) {
            k[i] = self.keyprotect.text.length ? (unsigned char)[self.keyprotect.text characterAtIndex:i % self.keyprotect.text.length] : 'x';
        }
        unsigned char m[LEN];
        unsigned char c1[LEN];
        unsigned char c2[LEN];
        
        NSData *cipher = [[NSData alloc] initWithBase64EncodedString:components[1] options:0];
        NSLog(@"cipher: %@", cipher);
        
        if (cipher) {
            memcpy(m, cipher.bytes, cipher.length);
            
            crypto_stream(c1, cipher.length, n, k);
            crypto_stream_xor(c2, m, cipher.length, n, k);
            
            NSData *decrypted = [NSData dataWithBytes:c2 length:cipher.length];
            NSLog(@"decrypted: %@", decrypted);
            
            NSString *keystring = [NSString stringWithData:decrypted];
            NSLog(@"keystring: %@", keystring);
            
            NSArray *keys = [keystring componentsSeparatedByString:@":"];
            NSLog(@"keys: %@", keys);
            
            if ([keys count] == 2) {
                
                YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
                NSData *pk = [[NSData alloc] initWithBase64EncodedString:keys[0] options:0];
                NSData *sk = [[NSData alloc] initWithBase64EncodedString:keys[1] options:0];
                if (pk && sk && [pk length] == crypto_box_PUBLICKEYBYTES && [sk length] == crypto_box_SECRETKEYBYTES) {
                    delegate.myself.myUser.pk = [[NSData alloc] initWithBase64EncodedString:keys[0] options:0];
                    delegate.myself.myUser.sk = [[NSData alloc] initWithBase64EncodedString:keys[1] options:0];
                } else {
                    self.importexport.text = @"error: invalid keys";
                    return;
                }
            } else {
                self.importexport.text = @"error: no pk and sk found";
                return;
            }
        } else {
            self.importexport.text = @"error: invalid cipher";
            return;
        }
    } else {
        self.importexport.text = @"error: invalid import/export";
        return;
    }
    
    [self changed];
}

- (IBAction)keypairPressed:(UIButton *)sender {
    YPOM *ypom = [[YPOM alloc] init];
    [ypom createKeyPair];
    NSLog(@"ypom p:%@", ypom.pk);
    NSLog(@"ypom s:%@", ypom.sk);
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    delegate.myself.myUser = [User userWithPk:ypom.pk
                                         name:self.name.text
                       inManagedObjectContext:delegate.managedObjectContext];
    delegate.myself.myUser.sk = ypom.sk;

    [self changed];
}
- (IBAction)keyprotectionChanged:(UITextField *)sender {
    [self changed];
}
- (IBAction)hostChanged:(UITextField *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    delegate.broker.host = sender.text;
    
    [self changed];
}

- (IBAction)portChanged:(UITextField *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    delegate.broker.port =  @([sender.text intValue]);
    
    [self changed];
}
- (IBAction)tlsChanged:(UISwitch *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    delegate.broker.tls = @(sender.on);
    
    [self changed];
}
- (IBAction)authChanged:(UISwitch *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    delegate.broker.auth = @(sender.on);
    
    [self changed];
}
- (IBAction)userChanged:(UITextField *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    delegate.broker.user = sender.text;
    
    [self changed];
}
- (IBAction)passwordChanged:(UITextField *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    delegate.broker.passwd = sender.text;
    
    [self changed];
}

-(IBAction)textFieldReturn:(id)sender
{
    [sender resignFirstResponder];
}


@end
