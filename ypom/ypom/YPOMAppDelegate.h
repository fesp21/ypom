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

@interface YPOMAppDelegate : UIResponder <UIApplicationDelegate, MQTTSessionDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) MQTTSession *session;
@property (strong, nonatomic) Myself *myself;

- (void)connect:(id)object;
- (void)disconnect:(id)object;

- (void)saveContext;
- (void)connectionClosed;
- (NSURL *)applicationDocumentsDirectory;

@end
