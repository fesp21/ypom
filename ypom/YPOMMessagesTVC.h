//
//  YPOMMessagesTVC.h
//  YPOM
//
//  Created by Christoph Krey on 12.11.13.
//  Copyright (c) 2013 Christoph Krey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTVC.h"
#import "User+Create.h"
#import <AddressBookUI/AddressBookUI.h>


@interface YPOMMessagesTVC : CoreDataTVC <UINavigationControllerDelegate, UIImagePickerControllerDelegate,ABPeoplePickerNavigationControllerDelegate>
@property (strong, nonatomic) User *user;

@end
