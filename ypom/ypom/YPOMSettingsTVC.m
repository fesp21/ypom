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
#import "NSString+stringWithData.h"
#import "NSString+HexToData.h"
#import "NSString+hexStringWithData.h"
#import "OsodiumSecretBox.h"

@interface YPOMSettingsTVC () <YPOMdelegate>
@property (weak, nonatomic) IBOutlet UITextField *identifier;
@property (weak, nonatomic) IBOutlet UITextField *phrase;
@property (weak, nonatomic) IBOutlet UITextView *cipher;

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

@property (strong, nonatomic)  UIDocumentInteractionController *dic;
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

    self.view.backgroundColor = delegate.theme.backgroundColor;
    self.tableView.tintColor = delegate.theme.yourColor;
    
    [self saveOld];
    
    [self changed];
}

- (void)saveOld
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;

    self.oldUser = delegate.myself.myUser;
    self.oldHost = delegate.broker.host;
    self.oldPort = [delegate.broker.port integerValue];
    self.oldUserID = delegate.broker.user;
    self.oldPasswd = delegate.broker.passwd;
    self.oldTls = [delegate.broker.tls boolValue];
    self.oldAuth = [delegate.broker.auth boolValue];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.listener = self;
    
    [self lineState];
}


- (void)viewWillDisappear:(BOOL)animated
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.listener = nil;

    if (![self.oldUser.identifier isEqualToString:delegate.myself.myUser.identifier]) {
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
    if (![self.oldUser.identifier isEqualToString:delegate.myself.myUser.identifier]) {
        [delegate subscribe:delegate.myself.myUser];
    }
    
    [delegate saveContext];
}

- (void)lineState
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    self.title = [NSString stringWithFormat:@"%@-%@", delegate.myself.myUser.identifier, delegate.broker.host];

    switch (delegate.state) {
        case 1:
            self.navigationController.navigationBar.barTintColor = delegate.theme.onlineColor;
            break;
        case -1:
            self.navigationController.navigationBar.barTintColor = delegate.theme.offlineColor;
            break;
        default:
            self.navigationController.navigationBar.barTintColor = delegate.theme.unknownColor;
            break;
    }
}

- (IBAction)refresh:(UIBarButtonItem *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;

    [delegate unsubscribe:self.oldUser];
    [delegate disconnect:nil];
    [delegate connect:nil];
    [delegate subscribe:delegate.myself.myUser];
    [self saveOld];
}

- (void)changed
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.identifier.text = delegate.myself.myUser.identifier;
    
    self.host.text = delegate.broker.host;
    self.port.text = [NSString stringWithFormat:@"%@", delegate.broker.port];
    self.tls.on = [delegate.broker.tls boolValue];
    
    self.auth.on = [delegate.broker.auth boolValue];
    self.user.text = delegate.broker.user;
    self.password.text = delegate.broker.passwd;
    
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

- (IBAction)backupPressed:(UIButton *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    if (self.phrase.text.length) {
        NSError *error;
        NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
        jsonObject[@"id"] = delegate.myself.myUser.identifier;
        jsonObject[@"pubkey"] = [delegate.myself.myUser.pubkey base64EncodedStringWithOptions:0];
        jsonObject[@"seckey"] = [delegate.myself.myUser.seckey base64EncodedStringWithOptions:0];
        jsonObject[@"verkey"] = [delegate.myself.myUser.verkey base64EncodedStringWithOptions:0];
        jsonObject[@"sigkey"] = [delegate.myself.myUser.sigkey base64EncodedStringWithOptions:0];
        
        NSData *json = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
        
        OSodiumSecretBox *secretBox = [[OSodiumSecretBox alloc] init];
        secretBox.phrase = [self.phrase.text dataUsingEncoding:NSUTF8StringEncoding];
        secretBox.secret = json;
        
        NSData *data = [[NSString hexStringWithData:[secretBox secretBoxOnWire]] dataUsingEncoding:NSUTF8StringEncoding];
        
        NSURL *directoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                                     inDomain:NSUserDomainMask
                                                            appropriateForURL:nil
                                                                       create:YES
                                                                        error:&error];
        NSString *fileName = [NSString stringWithFormat:@"ypom-backup.txt"];
        NSURL *fileURL = [directoryURL URLByAppendingPathComponent:fileName];
        
        [[NSFileManager defaultManager] createFileAtPath:[fileURL path]
                                                contents:data
                                              attributes:nil];
        
        self.dic = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
        self.dic.delegate = self;
        [self.dic presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES];
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Backup YPOM Settings"
                                                        message:@"Please specify phrase"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}
- (IBAction)invitePressed:(UIButton *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    NSError *error;
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    jsonObject[@"id"] = delegate.myself.myUser.identifier;
    jsonObject[@"pubkey"] = [delegate.myself.myUser.pubkey base64EncodedStringWithOptions:0];
    jsonObject[@"verkey"] = [delegate.myself.myUser.verkey base64EncodedStringWithOptions:0];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
    
    NSURL *directoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                                 inDomain:NSUserDomainMask
                                                        appropriateForURL:nil
                                                                   create:YES
                                                                    error:&error];
    NSString *fileName = [NSString stringWithFormat:@"ypom-invite.ypom"];
    NSURL *fileURL = [directoryURL URLByAppendingPathComponent:fileName];
    
    [[NSFileManager defaultManager] createFileAtPath:[fileURL path]
                                            contents:data
                                          attributes:nil];
    
    self.dic = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    self.dic.delegate = self;
    [self.dic presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES];
}

- (IBAction)loadPressed:(UIButton *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    if (self.phrase.text.length) {
        if (self.cipher.text.length) {
            
            OSodiumSecretBox *secretBox = [OSodiumSecretBox
                                           secretBoxFromData:[self.cipher.text hexToData]
                                           phrase:[self.phrase.text dataUsingEncoding:NSUTF8StringEncoding]
                                           ];
            if (secretBox) {
                NSLog(@"json %@", secretBox.secret);
                
                NSError *error;
                NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:secretBox.secret
                                                                           options:0
                                                                             error:&error];
                if (dictionary) {
#ifdef DEBUG
                    for (NSString *key in [dictionary allKeys]) {
                        NSLog(@"json %@:%@", key, dictionary[key]);
                    }
#endif
                    User *user = [User userWithIdentifier:dictionary[@"id"]
                                   inManagedObjectContext:delegate.managedObjectContext];
                    
                    user.pubkey = [[NSData alloc] initWithBase64EncodedString:dictionary[@"pubkey"] options:0];
                    user.seckey = [[NSData alloc] initWithBase64EncodedString:dictionary[@"seckey"] options:0];
                    user.sigkey = [[NSData alloc] initWithBase64EncodedString:dictionary[@"sigkey"] options:0];
                    user.verkey = [[NSData alloc] initWithBase64EncodedString:dictionary[@"verkey"] options:0];
                    
                    delegate.myself.myUser = user;
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Load YPOM Identiy"
                                                                    message:@"Illegal JSON"
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                }
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Load YPOM Identiy"
                                                                message:@"Cannot secretBoxOpen"
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Load YPOM Identity"
                                                            message:@"Please specify cipher"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Load YPOM Identity"
                                                        message:@"Please specify phrase"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction)textFieldReturn:(id)sender
{
    [sender resignFirstResponder];
}


@end
