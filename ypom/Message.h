//
//  Message.h
//  ypom
//
//  Created by Christoph Krey on 03.03.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Message : NSManagedObject

@property (nonatomic, retain) NSNumber * acknowledged;
@property (nonatomic, retain) NSData * content;
@property (nonatomic, retain) NSNumber * delivered;
@property (nonatomic, retain) NSNumber * msgid;
@property (nonatomic, retain) NSNumber * outgoing;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * contenttype;
@property (nonatomic, retain) User *belongsTo;

@end
