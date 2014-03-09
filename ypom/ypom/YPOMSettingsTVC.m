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
#import "NSString+HexToData.h"
#import "NSString+hexStringWithData.h"
#define LEN 512


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
    
    if (self.keyprotect.text.length) {
        NSError *error;
        NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
        jsonObject[@"username"] = delegate.myself.myUser.name;
        jsonObject[@"pk"] = [delegate.myself.myUser.pk base64EncodedStringWithOptions:0];
        jsonObject[@"sk"] = [delegate.myself.myUser.sk base64EncodedStringWithOptions:0];
        
        NSData *json = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
        
        NSLog(@"json: %@", json);
        
        unsigned char m[LEN];
        unsigned char c[LEN];
        
        memset(m, 0, crypto_secretbox_ZEROBYTES);
        memcpy(m + crypto_secretbox_ZEROBYTES, json.bytes, json.length);
        
        unsigned char h[crypto_hash_BYTES];
        NSData *key = [self.keyprotect.text dataUsingEncoding:NSUTF8StringEncoding];
        
        crypto_hash_sha256(h, key.bytes, key.length);
        
        unsigned char k[crypto_secretbox_KEYBYTES];
        memset(k, 0, crypto_secretbox_KEYBYTES);
        memcpy(k, h, MIN(crypto_secretbox_KEYBYTES,crypto_hash_BYTES));
        
        unsigned char n[crypto_secretbox_NONCEBYTES];
        randombytes(n, crypto_secretbox_NONCEBYTES);
        
        crypto_secretbox(c, m, crypto_secretbox_ZEROBYTES + json.length, n, k);
        
        NSString *nonceString = [NSString hexStringWithData:[NSData dataWithBytes:n length:crypto_secretbox_NONCEBYTES]];
        NSString *jsonString =  [NSString hexStringWithData:[NSData dataWithBytes:c + crypto_secretbox_BOXZEROBYTES length:json.length + crypto_secretbox_ZEROBYTES - crypto_secretbox_BOXZEROBYTES]];
        self.importexport.text = [NSString stringWithFormat:@"%@%@", nonceString, jsonString];
    } else {
        self.importexport.text = @"error: no keyprotection entered";
    }
}

- (IBAction)nameChanged:(UITextField *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.myself.myUser.name = sender.text;
    [self changed];
}

- (IBAction)loadPressed:(UIButton *)sender {
    
    unsigned char h[crypto_hash_BYTES];
    NSData *key = [self.keyprotect.text dataUsingEncoding:NSUTF8StringEncoding];
    crypto_hash_sha256(h, key.bytes, key.length);

    unsigned char k[crypto_secretbox_KEYBYTES];
    memset(k, 0, crypto_secretbox_KEYBYTES);
    memcpy(k, h, MIN(crypto_secretbox_KEYBYTES,crypto_hash_BYTES));
    
    NSData *data = [self.importexport.text hexToData];
    if (data) {
        if (data.length > crypto_secretbox_NONCEBYTES) {
            unsigned char n[crypto_secretbox_NONCEBYTES];
            memcpy(n, data.bytes, crypto_secretbox_NONCEBYTES);
            
            unsigned char m[LEN];
            unsigned char c[LEN];
            
            memset(c, 0, crypto_secretbox_BOXZEROBYTES);
            memcpy(c + crypto_secretbox_BOXZEROBYTES, data.bytes + crypto_secretbox_NONCEBYTES, data.length - crypto_secretbox_NONCEBYTES);
            
            if (!crypto_secretbox_open(m, c, crypto_secretbox_BOXZEROBYTES + data.length - crypto_secretbox_NONCEBYTES, n, k)) {
                NSData *decrypted = [NSData dataWithBytes:m + crypto_secretbox_ZEROBYTES length:data.length - crypto_secretbox_BOXZEROBYTES - crypto_secretbox_NONCEBYTES];
                
                if (decrypted) {
                    NSError *error;
                    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:decrypted options:0 error:&error];
                    
                    if (jsonObject) {
                        NSString *username = jsonObject[@"username"];
                        NSData *pk = [[NSData alloc] initWithBase64EncodedString:jsonObject[@"pk"] options:0];
                        NSData *sk = [[NSData alloc] initWithBase64EncodedString:jsonObject[@"sk"] options:0];
                        
                        YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
                        if (pk && sk && pk.length == crypto_box_PUBLICKEYBYTES && sk.length == crypto_box_SECRETKEYBYTES) {
                            delegate.myself.myUser.name = username;
                            delegate.myself.myUser.pk = pk;
                            delegate.myself.myUser.sk = sk;
                        } else {
                            self.importexport.text = @"error: invalid keys";
                            return;
                        }
                    } else {
                        self.importexport.text = @"error: invalid json";
                        return;
                    }
                } else {
                    self.importexport.text = @"error: not decrypted";
                    return;
                }
            } else {
                self.importexport.text = @"error: secretbox_open failed";
                return;
            }
        } else {
            self.importexport.text = @"error: invalid nonce";
            return;
        }
    } else {
        self.importexport.text = @"error: not base 64";
        return;
    }
    
    [self changed];
}

- (IBAction)keypairPressed:(UIButton *)sender {
    YPOM *ypom = [[YPOM alloc] init];
    [ypom createKeyPair];
    
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
