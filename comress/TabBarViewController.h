//
//  TabBarViewController.h
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "Database.h"
#import "AFManager.h"
#import "Device_token.h"
#import "Users.h"
#import "Blocks.h"

@interface TabBarViewController : UITabBarController
{
    Database *myDatabase;
    AFManager *myAfManager;
    FMDatabase *db;
    FMDatabaseQueue *databaseQueue;
    Users *user;
    Blocks *blocks;
}
@end
