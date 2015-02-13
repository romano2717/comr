//
//  AppDelegate.h
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FMDB.h"
#import "Database.h"
#import "AppWideImports.h"
#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "AFNetworkActivityLogger.h"
#import "AFManager.h"
#import "Synchronize.h"
#import "Device_token.h"
#import "Users.h"
#import "AFManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    DDFileLogger *fileLogger;
    Database *myDatabase;
    Device_token *device_token;
    Synchronize *sync;
    Users *user;
    AFManager *myAfManager;
}
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic)UIBackgroundTaskIdentifier bgTask;
@property (nonatomic, strong) NSTimer *syncTimer;

@end

