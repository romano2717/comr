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
    
    //prepare the db
    [myDatabase copyDbToDocumentsDir];
    
    //migrate database
    [myDatabase migrateDatabase];
    
    [application setKeepAliveTimeout:ping_interval handler:^{
        [self pingServer];
    }];
    
    sync = [Synchronize  sharedManager];

    self.syncTimer = [NSTimer scheduledTimerWithTimeInterval:sync_interval target:self selector:@selector(synchronizeUpload) userInfo:nil repeats:YES];
    
    
    //observer to call download post
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDownloadFinish) name:@"postDownloadFinish" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postImageDownloadFinish) name:@"postImageDownloadFinish" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentDownloadFinish) name:@"commentDownloadFinish" object:nil];
    
    return YES;
}

- (void)synchronizeUpload
{
    /*
     only upload data to server if db file was modified to avoid un-necessary queries on the db
     */
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:myDatabase.dbPath error:nil];
    NSDate *modDate = [attributes fileModificationDate];
    
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    
    NSDate *storedModDate = [userDef objectForKey:@"modDate"];
    
    if (storedModDate != modDate)
    {
        DDLogVerbose(@"Db file was modified!");
        [userDef setObject:modDate forKey:@"modDate"];
    }
    else
    {
        return; // db was not modified, don't do sync
    }

    if(myDatabase.initializingComplete == 0)
        return;
    
    //upload
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [sync uploadPost];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [sync uploadComment];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [sync uploadImage];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [sync uploadPostStatusChange];
    });
}

- (void)postDownloadFinish
{
    return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        FMDatabase *db = [myDatabase prepareDatabaseFor:self];
        FMResultSet *rs = [db executeQuery:@"select date from post_last_request_date"];
        NSDate *requestDate;
        if([rs next])
        {
            requestDate = [rs dateForColumn:@"date"];
            [sync startDownloadPostForPage:1 totalPage:0 requestDate:requestDate];
        }
        else
        {
            NSString *jsonDate = @"/Date(1388505600000+0800)/";
            NSDate *date = [self deserializeJsonDateString:jsonDate];
            [sync startDownloadPostForPage:1 totalPage:0 requestDate:date];
        }
    });
}

- (void)postImageDownloadFinish
{
    return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        FMDatabase *db = [myDatabase prepareDatabaseFor:self];
        FMResultSet *rs = [db executeQuery:@"select date from post_image_last_request_date"];
        NSDate *requestDate;
        if([rs next])
        {
            requestDate = [rs dateForColumn:@"date"];
            [sync startDownloadPostImagesForPage:1 totalPage:0 requestDate:requestDate];
        }
        else
        {
            NSString *jsonDate = @"/Date(1388505600000+0800)/";
            NSDate *date = [self deserializeJsonDateString:jsonDate];
            [sync startDownloadPostImagesForPage:1 totalPage:0 requestDate:date];
        }
    });
}

- (void)commentDownloadFinish
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        FMDatabase *db = [myDatabase prepareDatabaseFor:self];
        FMResultSet *rs = [db executeQuery:@"select date from comment_last_request_date"];
        NSDate *requestDate;
        if([rs next])
        {
            requestDate = [rs dateForColumn:@"date"];
            [sync startDownloadCommentsForPage:1 totalPage:0 requestDate:requestDate];
        }
        else
        {
            NSString *jsonDate = @"/Date(1388505600000+0800)/";
            NSDate *date = [self deserializeJsonDateString:jsonDate];
            [sync startDownloadCommentsForPage:1 totalPage:0 requestDate:date];
        }
    });
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
        
        [self synchronizeUpload];
        
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
    
    //-- Set Notification
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
    {
        // iOS 8 Notifications
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
        [application registerForRemoteNotifications];
    }
    else
    {
        // iOS < 8 Notifications
        [application registerForRemoteNotificationTypes: (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
    }
    
    
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

    FMDatabase *db = [myDatabase prepareDatabaseFor:self];
    
    FMResultSet *rs = [db executeQuery:@"select device_token from device_token"];
    BOOL q;
    
    if([rs next])
    {
        [db beginTransaction];
        q = [db executeUpdate:@"update device_token set device_token = ?",token];

        if(!q)
        {
            [db rollback];
            DDLogVerbose(@"error saving device token");
        }
        
        else
            [db commit];
        
    }
    else
    {
        [db beginTransaction];
        BOOL q2 = [db executeUpdate:@"insert into device_token (device_token) values (?)",token];
        if(!q2)
            [db rollback];
        else
            [db commit];
    }
    
    
    //register token to server
    myAfManager = [AFManager sharedMyAfManager];
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    device_token = [[Device_token alloc] init];
    user = [[Users alloc] init];
    
    NSNumber *deviceId = user.device_id ? user.device_id : [NSNumber numberWithInt:0];
    
    if([deviceId intValue] != 0) //the use is currently logged in
    {
        NSString *urlParams = [NSString stringWithFormat:@"deviceId=%@&deviceToken=%@",deviceId,device_token.device_token];
        
        [manager GET:[NSString stringWithFormat:@"%@%@%@",myAfManager.api_url,api_update_device_token,urlParams] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            DDLogVerbose(@"update device token %@",responseObject);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        }];
    }
}

@end
