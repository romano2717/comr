//
//  AppDelegate.m
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize bgTask;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    if(allowLogging)
        [[AFNetworkActivityLogger sharedLogger] startLogging];
    
    myDatabase = [Database sharedMyDbManager];
    
    //logging mechanism;
    fileLogger = [[DDFileLogger alloc] init];
    fileLogger.maximumFileSize  = 256000 * 1;  // 256 KB
    fileLogger.rollingFrequency =   60 * 60 * 120;  // 120 hour rolling or 5 days. unit in seconds
    fileLogger.logFileManager.maximumNumberOfLogFiles = 2;
    
    [DDLog addLogger:fileLogger];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    //migrate database
    //[myDatabase migrateDatabase];
    
    [application setKeepAliveTimeout:ping_interval handler:^{
        [self pingServer];
    }];
    
    sync = [Synchronize  sharedManager];
    [sync kickStartSync];
    
    return YES;
}

- (NSDate *)deserializeJsonDateString: (NSString *)jsonDateString
{
    NSInteger startPosition = [jsonDateString rangeOfString:@"("].location + 1; //start of the date value
    //NSInteger startPosition = [jsonDateString rangeOfString:@"("].location ;
    
    NSTimeInterval unixTime = [[jsonDateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
    
    NSDate *date =  [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    return date;
}

- (NSString *)serializedStringDateJson: (NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
    
    NSString *jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [date timeIntervalSince1970],[formatter stringFromDate:date]]; //three zeroes at the end of the unix timestamp are added because thats the millisecond part (WCF supports the millisecond precision)
    
    
    return jsonDate;
}

- (void)pingServer
{
    DDLogVerbose(@"Ping server...");
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [application endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
    
    if(bgTask == UIBackgroundTaskInvalid)
    {
        DDLogVerbose(@"create bg task and sync!");
        
        bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            DDLogVerbose(@"end bg task");
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    application.applicationIconBadgeNumber = 0;
    
    //-- Set Notification
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
    {
        // iOS 8 Notifications
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
        [application registerForRemoteNotifications];
    }
 
    //ask permission to use location
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    
    if([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        [locationManager requestAlwaysAuthorization];
    
    if([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
        [locationManager requestWhenInUseAuthorization];
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    
    NSString *token = [[[[deviceToken description]
                                 stringByReplacingOccurrencesOfString: @"<" withString: @""]
                                stringByReplacingOccurrencesOfString: @">" withString: @""]
                               stringByReplacingOccurrencesOfString: @" " withString: @""];

    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select device_token from device_token"];
        BOOL q;
        
        if([rs next])
        {

            q = [db executeUpdate:@"update device_token set device_token = ?",token];
            
            if(!q)
            {
                *rollback = YES;
                DDLogVerbose(@"error saving device token");
            }
        }
        else
        {

            BOOL q2 = [db executeUpdate:@"insert into device_token (device_token) values (?)",token];
            if(!q2)
            {
                *rollback = YES;
            }
        }
        
        NSNumber *deviceId = [myDatabase.userDictionary valueForKey:@"device_id"] ? [myDatabase.userDictionary valueForKey:@"device_id"] : 0;
        
        if([deviceId intValue] != 0) //the use is currently logged in
        {
            NSString *urlParams = [NSString stringWithFormat:@"deviceId=%@&deviceToken=%@",deviceId,[myDatabase.deviceTokenDictionary valueForKey:@"device_token"]];
            
            [myDatabase.AfManager GET:[NSString stringWithFormat:@"%@%@%@",myDatabase.api_url,api_update_device_token,urlParams] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                DDLogVerbose(@"update device token %@",responseObject);
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            }];
        }
    }];
    
    [myDatabase createDeviceToken];
}

@end
