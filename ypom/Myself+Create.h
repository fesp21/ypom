//
//  Myself+Create.h
//  ypom
//
//  Created by Christoph Krey on 27.02.14.
//  Copyright (c) 2014 Christoph Krey. All rights reserved.
//

#import "Myself.h"

@interface Myself (Create)
+ (Myself *)myselfWithUser:(User *)user
  inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Myself *)existsMyselfInManagedObjectContext:(NSManagedObjectContext *)context;

@end
