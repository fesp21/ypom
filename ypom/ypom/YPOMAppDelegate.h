//
//  YPOMAppDelegate.h
//  ypom
//
//  Created by Christoph Krey on 26.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MQTTClient/MQTTClient.h>
#import "Myself+Create.h"
#import "Broker+Create.h"
#import "User+Create.h"

@protocol YPOMdelegate <NSObject>

- (void)lineState;

@end

@interface YPOMAppDelegate : UIResponder <UIApplicationDelegate, MQTTSessionDelegate>

@property (weak, nonatomic) id<YPOMdelegate> listener;

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) MQTTSession *session;
@property (nonatomic) int state;
@property (strong, nonatomic) Myself *myself;
@property (strong, nonatomic) Broker *broker;

- (void)connect:(id)object;
- (void)unsubscribe:(User *)user;
- (void)subscribe:(User *)user;
- (void)disconnect:(id)object;

- (void)sendPush:(User *)user;

- (void)saveContext;
- (void)connectionClosed;
- (NSURL *)applicationDocumentsDirectory;


@end
