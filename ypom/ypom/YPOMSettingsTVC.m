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

@interface YPOMSettingsTVC ()
@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *pk;
@property (weak, nonatomic) IBOutlet UITextField *sk;
@property (weak, nonatomic) IBOutlet UITextField *host;
@property (weak, nonatomic) IBOutlet UITextField *port;
@property (weak, nonatomic) IBOutlet UITextField *user;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UISwitch *tls;
@property (weak, nonatomic) IBOutlet UISwitch *auth;

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
    [delegate unsubscribe:nil];
    [delegate disconnect:nil];
    [self changed];
}

- (void)viewWillDisappear:(BOOL)animated
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate connect:nil];
    [delegate saveContext];
}

- (void)changed
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.name.text = delegate.myself.myUser.name;
    
    self.pk.text = [delegate.myself.myUser.pk base64EncodedStringWithOptions:0];
    self.sk.text = [delegate.myself.myUser.sk base64EncodedStringWithOptions:0];
    
    self.host.text = delegate.broker.host;
    self.port.text = [NSString stringWithFormat:@"%@", delegate.broker.port];
    self.tls.on = [delegate.broker.tls boolValue];
    
    self.auth.on = [delegate.broker.auth boolValue];
    self.user.text = delegate.broker.user;
    self.password.text = delegate.broker.passwd;
    
}

- (IBAction)nameChanged:(UITextField *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.myself.myUser.name = sender.text;
    [self changed];
    [self.tableView resignFirstResponder];
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
