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
#import "User+Create.h"
#import "Broker+Create.h"
#import "Message+Create.h"
#include "isutf8.h"
#include "NSString+HexToData.h"
#include "NSString+stringWithData.h"

@interface YPOMAppDelegate ()
@property (nonatomic) UIBackgroundTaskIdentifier bgTask;
@property (strong, nonatomic) NSError *lastError;
@property (nonatomic) NSInteger errorCount;
@property (strong, nonatomic) NSData *deviceToken;
@end

@implementation YPOMAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"didFinishLaunchingWithOptions");
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSLog(@"applicationWillResignActive");
    
    [self saveContext];
    [self.session close];

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
        YPOM *ypom = [[YPOM alloc] init];
        [ypom createKeyPair];
        
        User *user = [User userWithPk:ypom.pk
                                 name:[NSString stringWithFormat:@"%@",
                                         [[UIDevice currentDevice].name stringByReplacingOccurrencesOfString:@" " withString:@"_"]]
                 inManagedObjectContext:self.managedObjectContext];
        
        user.sk = ypom.sk;
        
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

    self.session = [[MQTTSession alloc] initWithClientId:self.myself.myUser.name
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
    
    [self connect:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"applicationWillTerminate");
    
    [self saveContext];
    [self.session close];

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
        {
            [self.session subscribeToTopic:@"ypom/+"
                                   atLevel:2];
            [self.session subscribeToTopic:[NSString stringWithFormat:@"ypom/%@/+",
                                            [self.myself.myUser base32EncodedPk]]
                                   atLevel:2];

            NSError *error;
            NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
            jsonObject[@"_type"] = @"usr";
            jsonObject[@"name"] = self.myself.myUser.name;
            jsonObject[@"pk"] = [self.myself.myUser.pk base64EncodedStringWithOptions:0];
            if (self.deviceToken) {
                jsonObject[@"dev"] = [self.deviceToken base64EncodedStringWithOptions:0];
            }
            
            NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];

            [self.session publishData:data
                              onTopic:[NSString stringWithFormat:@"ypom/%@",
                                       [self.myself.myUser base32EncodedPk]]
                               retain:YES
                                  qos:2];
            
            break;
        }
        default:
            break;
    }
}


- (void)newMessage:(MQTTSession *)session
              data:(NSData *)data
           onTopic:(NSString *)topic
               qos:(int)qos
          retained:(BOOL)retained
               mid:(unsigned int)mid
{
    NSLog(@"newMessage: %@ on %@", data, topic);
    
    NSArray *components = [topic pathComponents];
    
    if ([components count] == 2) {
        
        NSError *error;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (dictionary) {
            if ([dictionary[@"_type"] isEqualToString:@"usr"]) {
                User *user = [User existsUserWithBase32EncodedPk:components[1]
                                          inManagedObjectContext:self.managedObjectContext];
                if (user) {
                    user.name = dictionary[@"name"];
                } else {
                    user = [User userWithBase32EncodedPk:components[1]
                                                    name:dictionary[@"name"]
                                  inManagedObjectContext:self.managedObjectContext];
                }
                
                [Message messageWithContent:nil
                                contentType:nil
                                  timestamp:[NSDate dateWithTimeIntervalSince1970:FUTURE]
                                   outgoing:YES
                                  belongsTo:user
                     inManagedObjectContext:self.managedObjectContext];
            } else {
                NSLog(@"unknown _type:%@", dictionary[@"_type"]);
            }
        } else {
            NSLog(@"illegal json:%@", error);
        }
        
    }
    
    if ([components count] == 3) {
        User *receiver = [User existsUserWithBase32EncodedPk:components[1]
                                      inManagedObjectContext:self.managedObjectContext];
        
        User *sender = [User existsUserWithBase32EncodedPk:components[2]
                                    inManagedObjectContext:self.managedObjectContext];
        
        YPOM *ypom = [YPOM ypomFromWire:[NSString stringWithData:data] pk:sender.pk sk:receiver.sk];
        
        if (ypom.message) {
            NSError *error;
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:ypom.message options:0 error:&error];
            if (dictionary) {
                if ([dictionary[@"_type"] isEqualToString:@"msg"]) {
                    NSData *content = dictionary[@"content"] ? [[NSData alloc] initWithBase64EncodedString:dictionary[@"content"] options:0] : nil;
                    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"timestamp"] doubleValue]];
                    NSString *contentType = dictionary[@"content-type"];
                    [Message messageWithContent:content
                                    contentType:contentType
                                      timestamp:timestamp
                                       outgoing:NO
                                      belongsTo:sender
                         inManagedObjectContext:self.managedObjectContext];
                    
                    YPOM *ypom = [[YPOM alloc] init];
                    ypom.pk = sender.pk;
                    ypom.sk = receiver.sk;
                    
                    NSError *error;
                    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
                    
                    jsonObject[@"_type"] = @"ack";
                    jsonObject[@"timestamp"] = [NSString stringWithFormat:@"%.3f", [timestamp timeIntervalSince1970]];
                    
                    ypom.message = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
                    
                    [self.session publishData:[[ypom wireString] dataUsingEncoding:NSUTF8StringEncoding]
                                      onTopic:[NSString stringWithFormat:@"ypom/%@/%@",
                                               [sender base32EncodedPk],
                                               [receiver base32EncodedPk]]
                                       retain:NO
                                          qos:2];
                    
                } else if ([dictionary[@"_type"] isEqualToString:@"ack"]) {
                    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"timestamp"] doubleValue]];
                    Message *message = [Message existsMessageWithTimestamp:timestamp
                                                                  outgoing:YES
                                                                 belongsTo:sender                                                        inManagedObjectContext:self.managedObjectContext];
                    message.acknowledged = @(TRUE);
                } else {
                    NSLog(@"unknown _type:%@", dictionary[@"_type"]);
                }
            } else {
                NSLog(@"illegal json:%@", error);
            }
            
        } else {
            [Message messageWithContent:[@"Can't boxOpen" dataUsingEncoding:NSUTF8StringEncoding]
                            contentType:nil
                              timestamp:[NSDate date]
                               outgoing:NO
                              belongsTo:sender
                 inManagedObjectContext:self.managedObjectContext];
        }
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

- (void)connect:(id)object
{
    [self.session connectToHost:self.broker.host
                           port:[self.broker.port unsignedIntValue]
                       usingSSL:[self.broker.tls boolValue]];
}

- (void)unsubscribe:(id)object
{
    [self.session unsubscribeTopic:@"ypom/+"];
    [self.session unsubscribeTopic:[NSString stringWithFormat:@"ypom/%@/+", self.myself.myUser.name]];
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

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"App didReceiveRemoteNotification fetchCompletionHandler %@", userInfo);
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"App didRegisterForRemoteNotificationsWithDeviceToken %@", deviceToken);
    self.deviceToken = deviceToken;
}

@end

