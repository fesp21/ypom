//
//  YPOMAppDelegate.m
//  ypom
//
//  Created by Christoph Krey on 26.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "YPOMAppDelegate.h"
#import "YPOM.h"
#import "YPOM+Wire.h"
#import <CoreData/CoreData.h>
#import "Message+Create.h"
#import "Device+Create.h"
#import "isutf8.h"
#import "NSString+HexToData.h"
#import "NSString+stringWithData.h"
#import "NSString+hexStringWithData.h"
#import "NWPusher.h"
#import "OSodiumSign.h"
#import "OSodiumBox.h"
#import "YPOMInvitation.h"
#import "Group+Create.h"
#import "UserGroup.h"
#import "User+Create.h"

@interface YPOMAppDelegate ()
@property (nonatomic) UIBackgroundTaskIdentifier bgTask;
@property (strong, nonatomic) NSError *lastError;
@property (nonatomic) NSInteger errorCount;
@property (strong, nonatomic) NSData *deviceToken;
@property (strong, nonatomic) NSTimer *backgroundTimer;
@property (strong, nonatomic) void (^handler)(UIBackgroundFetchResult result);
@property (strong, nonatomic) NWPusher *pusher;
@property (nonatomic) NWPusherResult pusherResult;

@property (strong, nonatomic) UIDocumentInteractionController *dic;
@property (strong, nonatomic) YPOMInvitation *invitation;
@end

@implementation YPOMAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"didFinishLaunchingWithOptions");
    
    [OSodium theOSodium];
    
    NSDictionary *appDefaults = @{
                                  @"theme" : @"default",
                                  @"notificationLevel" : @(3),
                                  @"imageSize" : @(640.0),
                                  };
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];

    self.themes = [[YPOMThemes alloc] init];
    self.theme = [self.themes selectTheme:[[NSUserDefaults standardUserDefaults] stringForKey:@"theme"]];
    self.notificationLevel = [[NSUserDefaults standardUserDefaults] integerForKey:@"notificationLevel"];
    self.imageSize = [[NSUserDefaults standardUserDefaults] doubleForKey:@"imageSize"];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeNewsstandContentAvailability)];
    
    return YES;
}

- (void)setTheme:(YPOMTheme *)theme
{
    _theme = theme;
    [[NSUserDefaults standardUserDefaults] setObject:theme.name forKey:@"theme"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setNotificationLevel:(NSUInteger)notificationLevel
{
    _notificationLevel = notificationLevel;
    [[NSUserDefaults standardUserDefaults] setObject:@(notificationLevel) forKey:@"notificationLevel"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setImageSize:(double)imageSize
{
    _imageSize = imageSize;
    [[NSUserDefaults standardUserDefaults] setObject:@(imageSize) forKey:@"imageSize"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSLog(@"applicationWillResignActive");
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;

    [self saveContext];
    [self disconnect:nil];
    [self.pusher disconnect];
    self.pusher = nil;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"applicationDidEnterBackground");
    
    self.bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
                   {
                       NSLog(@"BackgroundTaskExpirationHandler");
                       [self connectionClosed];
                   }];

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"applicationWillEnterForeground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"applicationDidBecomeActive");
    
    self.myself = [Myself existsMyselfInManagedObjectContext:self.managedObjectContext];
    if (!self.myself) {
        User *user = [User newUserInManageObjectContext:self.managedObjectContext];
        
        self.myself = [Myself myselfWithUser:user
                      inManagedObjectContext:self.managedObjectContext];
    }
    
    self.broker = [Broker existsBroker:self.managedObjectContext];
    if (!self.broker) {
        self.broker = [Broker brokerWithHost:@"localhost"
                                        port:1883
                                         tls:NO
                                        auth:NO
                                        user:@""
                                    password:@""
                      inManagedObjectContext:self.managedObjectContext];
    }

    if (self.state != 1) {
        [self connect:nil];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"applicationWillTerminate");
    
    [self saveContext];
    [self disconnect:nil];
    [self.pusher disconnect];
    self.pusher = nil;

}

- (void)connectionClosed
{
    NSLog(@"connectionClosed");
    
    if (self.bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }
}

- (void)saveContext
{
    NSLog(@"saveContext");
    
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"YPOM" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"MQTTInspector.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             nil];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - MQTTSessionDelegate

- (void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error
{
#ifdef DEBUG
    NSArray *events = @[
                        @"MQTTSessionEventConnected",
                        @"MQTTSessionEventConnectionRefused",
                        @"MQTTSessionEventConnectionClosed",
                        @"MQTTSessionEventConnectionError",
                        @"MQTTSessionEventProtocolError"
                        ];
    
    NSLog(@"handleEvent: %@ (%d) %@", events[eventCode % [events count]], eventCode, [error description]);
#endif
    
    if (session != self.session) {
#ifdef DEBUG
        NSLog(@"handleEvent: old Session");
#endif
        return;
    }
    
    if (error) {
        if ((self.lastError.domain == error.domain) && (self.lastError.code == error.code)) {
            self.errorCount++;
        } else {
            self.errorCount = 1;
        }
        if (self.errorCount == 1 && [error.domain isEqualToString:NSOSStatusErrorDomain] && error.code == errSSLClosedAbort) {
            [self performSelector:@selector(connect:) withObject:nil afterDelay:.25];
        }
    }
    self.lastError = error;
    
    switch (eventCode) {
        case MQTTSessionEventConnected:
            [self subscribe:self.myself.myUser];
            self.state = 1;
            break;
        case MQTTSessionEventConnectionError:
            self.state = -1;
        default:
            self.state = 0;
            break;
    }
    if (self.listener) {
        [self.listener lineState];
    }
}

- (void)newMessage:(MQTTSession *)session
              data:(NSData *)data
           onTopic:(NSString *)topic
               qos:(int)qos
          retained:(BOOL)retained
               mid:(unsigned int)mid
{
    NSLog(@"newMessage: %@... on %@",
          [data subdataWithRange:NSMakeRange(0, MIN(16, data.length))],
          topic);
    
    NSArray *components = [topic pathComponents];
    
    
    if ([components count] == 3) {
        User *receiver = [User existsUserWithIdentifier:components[1]
                                 inManagedObjectContext:self.managedObjectContext];
        
        User *sender = [User existsUserWithIdentifier:components[2]
                               inManagedObjectContext:self.managedObjectContext];
        
        if (receiver && [receiver.identifier isEqualToString:self.myself.myUser.identifier] && sender) {
            
            NSData *binData = [[NSData alloc] initWithBase64EncodedData:data options:0];
            
            OSodiumSign *sign = [OSodiumSign signFromData:binData
                                                   verkey:sender.verkey];
            if (sign) {
                OSodiumBox *box = [OSodiumBox boxFromData:sign.secret
                                                   pubkey:sender.pubkey
                                                   seckey:receiver.seckey];
                if (box) {
                    NSError *error;
                    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:box.secret options:0 error:&error];
                    if (dictionary) {
                        if ([dictionary[@"_type"] isEqualToString:@"msg"]) {
                            NSData *content = dictionary[@"content"] ? [[NSData alloc] initWithBase64EncodedString:dictionary[@"content"] options:0] : nil;
                            NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"timestamp"] doubleValue]];
                            NSString *contentType = dictionary[@"content-type"];
                            NSDictionary *groupDictionary = dictionary[@"group"];
                            NSString *groupIdentifier = groupDictionary[@"id"];
                            User *belongsTo;
                            if (groupIdentifier) {
                                belongsTo = [User existsUserWithIdentifier:groupIdentifier inManagedObjectContext:self.managedObjectContext];
                            } else {
                                belongsTo = sender;
                            }
                            Message *message = [Message messageWithContent:content
                                                               contentType:contentType
                                                                 timestamp:timestamp
                                                                  outgoing:NO
                                                                 belongsTo:belongsTo
                                                    inManagedObjectContext:self.managedObjectContext];
                            //update
                            belongsTo.identifier = belongsTo.identifier;
                            [UIApplication sharedApplication].applicationIconBadgeNumber++;
                            UITabBarController *tbc = (UITabBarController *)self.window.rootViewController;
                            UITabBarItem *tbi = tbc.tabBar.items[0];
                            [tbi setBadgeValue:@"📧"];
                            
                            // send notification
                            
                            if (self.notificationLevel) {
                                UILocalNotification *notification = [[UILocalNotification alloc] init];
                                NSString *body = @"Message";
                                if (self.notificationLevel > 1) {
                                    body = [body stringByAppendingFormat:@" from 👤%@", [sender displayName]];
                                    if (self.notificationLevel > 2) {
                                        body = [body stringByAppendingFormat:@": %@", [message textOfMessage]];
                                    }
                                }
                                notification.alertBody = body;
                                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                            }

                            message.acknowledged = @(TRUE);
                            if (!groupIdentifier) {
                                message.acknowledged = @(TRUE);
                                NSError *error;
                                NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
                                jsonObject[@"_type"] = @"ack";
                                jsonObject[@"timestamp"] = [NSString stringWithFormat:@"%.3f", [timestamp timeIntervalSince1970]];
                                if (self.deviceToken) {
                                    jsonObject[@"dev"] = [self.deviceToken base64EncodedStringWithOptions:0];
                                }
                                
                                NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
                                [self safeSend:data to:sender];
                            }
                            
                        } else if ([dictionary[@"_type"] isEqualToString:@"ack"]) {
                            NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"timestamp"] doubleValue]];
                            Message *message = [Message existsMessageWithTimestamp:timestamp
                                                                          outgoing:YES
                                                                         belongsTo:sender                                                        inManagedObjectContext:self.managedObjectContext];
                            message.acknowledged = @(TRUE);
                            NSString *deviceTokenString = dictionary[@"dev"];
                            if (deviceTokenString) {
                                NSData *deviceToken = [[NSData alloc] initWithBase64EncodedString:deviceTokenString
                                                                                          options:0];
                                if (deviceToken) {
                                    [Device deviceWithToken:deviceToken belongsTo:sender];
                                }
                            }
                            
                        } else if ([dictionary[@"_type"] isEqualToString:@"see"]) {
                            NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"timestamp"] doubleValue]];
                            Message *message = [Message existsMessageWithTimestamp:timestamp
                                                                          outgoing:YES
                                                                         belongsTo:sender                                                        inManagedObjectContext:self.managedObjectContext];
                            message.seen = @(TRUE);
                            
                        } else if ([dictionary[@"_type"] isEqualToString:@"inv"]) {
                            self.invitation = [[YPOMInvitation alloc] init];
                            self.invitation.user = sender;
                            self.invitation.group = dictionary[@"group"];
                            [self.invitation show];
                            
                            // send notification
                            
                            if (self.notificationLevel) {
                                UILocalNotification *notification = [[UILocalNotification alloc] init];
                                NSString *body = @"Invitation";
                                if (self.notificationLevel > 1) {
                                    body = [body stringByAppendingFormat:@" from 👤%@", [sender displayName]];
                                }
                                notification.alertBody = body;
                                [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                            }

                            
                        } else if ([dictionary[@"_type"] isEqualToString:@"join"]) {
                            NSDictionary *groupDictionary = dictionary[@"group"];
                            NSString * groupIdentifier = groupDictionary[@"id"];
                            Group *group = [Group existsGroupWithIdentifier:groupIdentifier
                                                     inManagedObjectContext:self.managedObjectContext];
                            if (group) {
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"YPOM Group Join"
                                                                                message:[NSString stringWithFormat:@"👤%@ 👥%@",
                                                                                         [sender displayName],
                                                                                         [group displayName]
                                                                                         ]
                                                                               delegate:self
                                                                      cancelButtonTitle:@"OK"
                                                                      otherButtonTitles:nil];
                                [alert show];
                                
                                [group addUser:sender];
                                [group tell];
                            }
                            
                        } else if ([dictionary[@"_type"] isEqualToString:@"leave"]) {
                            NSDictionary *groupDictionary = dictionary[@"group"];
                            NSString * groupIdentifier = groupDictionary[@"id"];
                            Group *group = [Group existsGroupWithIdentifier:groupIdentifier
                                                     inManagedObjectContext:self.managedObjectContext];
                            if (group) {
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"YPOM Group Leave"
                                                                                message:[NSString stringWithFormat:@"👤%@ 👥%@",
                                                                                         [sender displayName],
                                                                                         [group displayName]
                                                                                         ]
                                                                               delegate:self
                                                                      cancelButtonTitle:@"OK"
                                                                      otherButtonTitles:nil];
                                [alert show];
                                
                                [group removeUser:sender];
                                [group tell];
                            }
                            
                        } else if ([dictionary[@"_type"] isEqualToString:@"tell"]) {
                            NSDictionary *groupDictionary = dictionary[@"group"];
                            NSString * groupIdentifier = groupDictionary[@"id"];
                            Group *group = [Group existsGroupWithIdentifier:groupIdentifier
                                                     inManagedObjectContext:self.managedObjectContext];
                            if (group) {
                                [group listen:groupDictionary];
                            }
                        } else {
                            NSLog(@"unknown _type:%@", dictionary[@"_type"]);
                        }
                    } else {
                        NSLog(@"illegal json:%@", error);
                    }
                    
                    
                } else {
                    [Message messageWithContent:[@"Can't boxOpen" dataUsingEncoding:NSUTF8StringEncoding]
                                    contentType:@"text/plain; charset:\"utf-8\""
                                      timestamp:[NSDate date]
                                       outgoing:NO
                                      belongsTo:sender
                         inManagedObjectContext:self.managedObjectContext];
                }
            } else {
                [Message messageWithContent:[@"Can't signOpen" dataUsingEncoding:NSUTF8StringEncoding]
                                contentType:@"text/plain; charset:\"utf-8\""
                                  timestamp:[NSDate date]
                                   outgoing:NO
                                  belongsTo:sender
                     inManagedObjectContext:self.managedObjectContext];
            }
        } else {
            NSLog(@"unkown sender/receiver");
        }
        
    }
    
    if (self.listener) {
        [self.listener lineState];
    }
    [self saveContext];
}

- (void)messageDelivered:(MQTTSession *)session msgID:(UInt16)msgID
{
    NSLog(@"messageDelivered: %ud", msgID);
    Message *message = [Message existsMessageWithMsgId:msgID inManagedObjectContext:self.managedObjectContext];
    if (message) {
        message.delivered = @(TRUE);
    }
}

- (void)buffered:(MQTTSession *)session queued:(NSUInteger)queued flowingIn:(NSUInteger)flowingIn flowingOut:(NSUInteger)flowingOut
{
#ifdef DEBUG
    NSLog(@"Connection buffered q%lu i%lu o%lu", (unsigned long)queued, (unsigned long)flowingIn, (unsigned long)flowingOut);
#endif
    if (queued + flowingIn + flowingOut) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
    } else {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;
    }
}

- (void)connect:(id)object
{
    self.session = [[MQTTSession alloc] initWithClientId:self.myself.myUser.identifier
                                                userName:[self.broker.auth boolValue] ? self.broker.user : nil
                                                password:[self.broker.auth boolValue] ? self.broker.passwd : nil
                                               keepAlive:60
                                            cleanSession:NO
                                                    will:NO
                                               willTopic:nil
                                                 willMsg:nil
                                                 willQoS:0
                                          willRetainFlag:NO
                                           protocolLevel:3
                                                 runLoop:[NSRunLoop currentRunLoop]
                                                 forMode:NSRunLoopCommonModes];
    self.session.delegate = self;
    
    [self.session connectToHost:self.broker.host
                           port:[self.broker.port unsignedIntValue]
                       usingSSL:[self.broker.tls boolValue]];
}

- (void)subscribe:(User *)user
{
    [self.session subscribeToTopic:[NSString stringWithFormat:@"ypom/%@/+", user.identifier]
                           atLevel:2];
}

- (void)unsubscribe:(User *)user
{
    [self.session unsubscribeTopic:[NSString stringWithFormat:@"ypom/%@/+", user.identifier]];
}

- (void)disconnect:(id)object
{
    [self.session close];
}

/*
 *
 * Remote Notifications
 *
 */

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"App didReceiveRemoteNotification %@", userInfo);
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"App didReceiveRemoteNotification fetchCompletionHandler %@", userInfo);
    
    if (self.state == 1 || [UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        completionHandler(UIBackgroundFetchResultNoData);
    } else {
        self.handler = completionHandler;
        self.backgroundTimer = [NSTimer scheduledTimerWithTimeInterval:25
                                                                target:self
                                                              selector:@selector(backgroundDisconnect:)
                                                              userInfo:nil
                                                               repeats:NO];
        [self connect:nil];
        
    }
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)backgroundDisconnect:(NSTimer *)timer
{
    self.backgroundTimer = nil;
    if (self.state == 1 && [UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        [self disconnect:nil];
    }
    self.handler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"App didRegisterForRemoteNotificationsWithDeviceToken %@", deviceToken);
    self.deviceToken = deviceToken;
}

- (void)sendPush:(User *)user
{
    if ([user.hasDevices count]) {
        NSURL *url = [NSBundle.mainBundle URLForResource:@"ypom-dev.p12" withExtension:nil];
        NSData *pkcs12 = [NSData dataWithContentsOfURL:url];
        if (!self.pusher) {
            self.pusher = [[NWPusher alloc] init];
            self.pusherResult = [self.pusher connectWithPKCS12Data:pkcs12 password:@"pa$$word"];
        }
        if (self.pusherResult == kNWPusherResultSuccess) {
            NSLog(@"Connected to APN");
        } else {
            NSLog(@"Unable to connect: %@", [NWPusher stringFromResult:self.pusherResult]);
            self.pusher = nil;
        }
        
        if (self.pusherResult == kNWPusherResultSuccess) {
            for (Device *dev in user.hasDevices) {
                NSString *payload = @"{\"aps\":{\"content-available\":\"1\"}}";
                NSString *token = [NSString hexStringWithData:dev.deviceToken];
                NWPusherResult pushed = [self.pusher pushPayload:payload token:token identifier:rand()];
                if (pushed == kNWPusherResultSuccess) {
                    NSLog(@"Notification sending");
                } else {
                    NSLog(@"Unable to sent: %@", [NWPusher stringFromResult:pushed]);
                    [self.pusher disconnect];
                    self.pusher = nil;
                }
                if (pushed) {
                    NSUInteger identifier = 0;
                    NWPusherResult accepted = [self.pusher fetchFailedIdentifier:&identifier];
                    if (accepted == kNWPusherResultSuccess) {
                        NSLog(@"Notification sent successfully");
                    } else {
                        NSLog(@"Notification with identifier %i rejected: %@", (int)identifier,
                              [NWPusher stringFromResult:accepted]);
                    }
                }
            }
        }
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"App didReceiveLocalNotification %@", notification);
    // nix tun
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
#ifdef DEBUG
    NSLog(@"openURL:%@ sourceApplication:%@ annotation:%@", url, sourceApplication, annotation);
#endif
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"YPOM File"
                                                    message:@"proccessing..."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    BOOL result = TRUE;
    NSString *identifier;
    [self disconnect:nil];
    
    if (url) {
        NSError *error;
        NSInputStream *input = [NSInputStream inputStreamWithURL:url];
        if (![input streamError]) {
            [input open];
            if (![input streamError]) {
                
                NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithStream:input options:0 error:&error];
                if (dictionary) {
#ifdef DEBUG
                    for (NSString *key in [dictionary allKeys]) {
                        NSLog(@"json %@:%@", key, dictionary[key]);
                    }
#endif
                    identifier = dictionary[@"id"];
                    NSData *pubkey = [[NSData alloc] initWithBase64EncodedString:dictionary[@"pubkey"] options:0];
                    NSData *verkey = [[NSData alloc] initWithBase64EncodedString:dictionary[@"verkey"] options:0];
                    
                    if (identifier && pubkey && verkey) {
                        User *user = [User userWithIdentifier:identifier inManagedObjectContext:self.managedObjectContext];
                        user.pubkey = pubkey;
                        user.verkey = verkey;
                        
                        NSString *loginString = dictionary[@"login"];
                        if (loginString) {
                            
                            NSData *login = [[NSData alloc] initWithBase64EncodedString:loginString options:0];
                            
                            if (login) {
                                
                                OSodiumSign *sign = [OSodiumSign signFromData:login
                                                                       verkey:verkey];
                                if (sign) {
                                    OSodiumBox *box = [OSodiumBox boxFromData:sign.secret
                                                                       pubkey:pubkey
                                                                       seckey:self.myself.myUser.seckey];
                                    if (box) {
                                        NSError *error;
                                        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:box.secret options:0 error:&error];
                                        if (dictionary) {
                                            self.broker.host = dictionary[@"host"];
                                            NSString *portString = dictionary[@"port"];
                                            self.broker.port = @([portString integerValue]);
                                            NSString *tlsString = dictionary[@"tls"];
                                            self.broker.tls = @([tlsString boolValue]);
                                            NSString *authString = dictionary[@"auth"];
                                            self.broker.auth = @([authString boolValue]);
                                            self.broker.user = dictionary[@"user"];
                                            self.broker.passwd = dictionary[@"passwd"];
                                            alert.message = [NSString stringWithFormat:@"Successfully processed %@", identifier];
                                        } else {
                                            alert.message = @"illegal json in login data";
                                            result = FALSE;
                                        }
                                    } else {
                                        alert.message = @"cannot boxOpen login data";
                                        result = FALSE;
                                    }
                                } else {
                                    alert.message = @"signature in login data wrong";
                                    result = FALSE;
                                }
                            } else {
                                alert.message = [NSString stringWithFormat:@"Invalid login data %@", loginString];
                            }
                        } else {
                            alert.message = [NSString stringWithFormat:@"Successfully processed w/o login data %@", identifier];
                        }
                    } else {
                        alert.message = @"Error invalid ypom file";
                        result = FALSE;
                    }
                } else {
                    alert.message = @"Error illegal json in file";
                    result = FALSE;
                }
            } else {
                alert.message = [NSString stringWithFormat:@"Error open %@ %@", [input streamError], url];
                result = FALSE;
            }
        } else {
            alert.message = [NSString stringWithFormat:@"Error inputStreamWithURL %@ %@", [input streamError], url];
            result = FALSE;
        }
    }
    [self saveContext];
    [alert show];
    return result;
}

- (UInt16)safeSend:(NSData *)data to:(User *)user
{
    OSodiumBox *box = [[OSodiumBox alloc] init];
    box.pubkey = user.pubkey;
    box.seckey = self.myself.myUser.seckey;
    
    box.secret = data;
    
    OSodiumSign *sign = [[OSodiumSign alloc] init];
    sign.verkey = self.myself.myUser.verkey;
    sign.sigkey = self.myself.myUser.sigkey;
    sign.secret = [box boxOnWire];
    
    UInt16 msgId = [self.session publishData:[[sign signOnWire] base64EncodedDataWithOptions:0]
                                     onTopic:[NSString stringWithFormat:@"ypom/%@/%@",
                                              user.identifier,
                                              self.myself.myUser.identifier]
                                      retain:NO
                                         qos:2];
    return msgId;
}

@end

