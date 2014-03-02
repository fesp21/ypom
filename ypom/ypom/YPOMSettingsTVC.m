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
    [delegate disconnect:nil];
    [self changed];
}

- (void)viewWillDisappear:(BOOL)animated
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate connect:nil];
}

- (void)changed
{
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.name.text = delegate.myself.myUser.name;
    
    self.pk.text = [delegate.myself.myUser.pk base64EncodedStringWithOptions:0];
    self.sk.text = [delegate.myself.myUser.sk base64EncodedStringWithOptions:0];
    
    self.host.text = delegate.myself.myUser.belongsTo.host;
    self.port.text = [NSString stringWithFormat:@"%@", delegate.myself.myUser.belongsTo.port];
    self.tls.on = [delegate.myself.myUser.belongsTo.tls boolValue];
    
    self.auth.on = [delegate.myself.myUser.belongsTo.auth boolValue];
    self.user.text = delegate.myself.myUser.belongsTo.user;
    self.password.text = delegate.myself.myUser.belongsTo.passwd;
    
    [self.tableView resignFirstResponder];
}

- (IBAction)nameChanged:(UITextField *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;

    User *user = [User existsUserWithName:sender.text broker:delegate.myself.myUser.belongsTo inManagedObjectContext:delegate.managedObjectContext];
    if (!user) {
        user = [User userWithName:sender.text
                               pk:nil
                               sk:nil
                           broker:delegate.myself.myUser.belongsTo
           inManagedObjectContext:delegate.managedObjectContext];
    }
    delegate.myself.myUser = user;
    [self changed];
}

- (IBAction)keypairPressed:(UIButton *)sender {
    YPOM *ypom = [[YPOM alloc] init];
    [ypom createKeyPair];
    
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.myself.myUser.pk = ypom.pk;
    delegate.myself.myUser.sk = ypom.sk;
    
    [self changed];
}
- (IBAction)hostChanged:(UITextField *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    Broker *broker = [Broker existsBrokerWithHost:sender.text
                                             port:[self.port.text intValue]
                           inManagedObjectContext:delegate.managedObjectContext];
    if (!broker) {
        broker = [Broker brokerWithHost:sender.text
                                   port:[self.port.text intValue]
                                    tls:self.tls.on
                                   auth:self.auth.on
                                   user:self.user.text
                               password:self.password.text
                 inManagedObjectContext:delegate.managedObjectContext];
    }
    delegate.myself.myUser.belongsTo = broker;

    [self changed];
}
- (IBAction)portChanged:(UITextField *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    Broker *broker = [Broker existsBrokerWithHost:self.host.text
                                             port:[sender.text intValue]
                           inManagedObjectContext:delegate.managedObjectContext];
    if (!broker) {
        broker = [Broker brokerWithHost:self.host.text
                                   port:[sender.text intValue]
                                    tls:self.tls.on
                                   auth:self.auth.on
                                   user:self.user.text
                               password:self.password.text
                 inManagedObjectContext:delegate.managedObjectContext];
    }
    delegate.myself.myUser.belongsTo = broker;
    [self changed];
}
- (IBAction)tlsChanged:(UISwitch *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    delegate.myself.myUser.belongsTo.tls = @(sender.on);
    
    [self changed];
}
- (IBAction)authChanged:(UISwitch *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    delegate.myself.myUser.belongsTo.auth = @(sender.on);
    
    [self changed];
}
- (IBAction)userChanged:(UITextField *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    delegate.myself.myUser.belongsTo.user = sender.text;
    
    [self changed];
}
- (IBAction)passwordChanged:(UITextField *)sender {
    YPOMAppDelegate *delegate = (YPOMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    delegate.myself.myUser.belongsTo.passwd = sender.text;
    
    [self changed];
    [sender resignFirstResponder];
}


@end
