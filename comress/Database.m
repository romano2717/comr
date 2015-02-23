//
//  Database.m
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Database.h"

static const int newDatabaseVersion = 2; //this database version is incremented everytime the database version is updated

@implementation Database

@synthesize initializingComplete;


+(id)sharedMyDbManager {
    static Database *sharedMyDbManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyDbManager = [[self alloc] init];
    });
    return sharedMyDbManager;
}

-(id)init {
    if (self = [super init]) {
        initializingComplete = 0;
    }
    return self;
}

- (FMDatabase *)prepareDatabaseFor:(id) obj
{
    NSString *dbPath = [self dbPath];

    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    if(![db open])
        DDLogVerbose(@"db open failed for %@ [%@-%@]",obj,THIS_FILE, THIS_METHOD);
    
    return db;
}

- (NSString*)dbPath;
{
    NSArray *Paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *DocumentDir = [Paths objectAtIndex:0];
    
    return [DocumentDir stringByAppendingPathComponent:@"comress.sqlite"];
}

- (void)copyDbToDocumentsDir
{
    BOOL isExist;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    isExist = [fileManager fileExistsAtPath:[self dbPath]];
    NSString *FileDB = [[[NSBundle mainBundle]resourcePath]stringByAppendingPathComponent:@"comress.sqlite"];
    if (isExist)
    {
        return;
    }
    else
    {
        NSError *error;
        
        [fileManager copyItemAtPath:FileDB toPath:[self dbPath] error:&error];
        
        if(error)
        {
            DDLogVerbose(@"settings copy error %@ [%@-%@]",error,THIS_FILE,THIS_METHOD);
            return;
        }
    }
}

#pragma - mark database migration

-(BOOL)migrateDatabase
{
    BOOL success;
    
    FMDatabase *db = [self prepareDatabaseFor:self];
    if(allowLogging)
        db.traceExecution = NO;
    [db open];
    
    FMResultSet *rs = [db executeQuery:@"select max(version) as version from db_version"];
    
    int currentAppDbVersion = 1;
    while ([rs next]) {
        currentAppDbVersion = [rs intForColumn:@"version"];
    }
    
    if(currentAppDbVersion < newDatabaseVersion)
    {
        //do the migration!
        
        /*
         January 29, 2015 3:47:08
         add column: email
         for table: users
         purpose: additional field
         */
        
        if(![db columnExists:@"email" inTableWithName:@"users"])
        {
            [db beginTransaction];
            success = [db executeUpdate:@"ALTER TABLE users ADD COLUMN email STRING"];
            
            if(!success)
                [db rollback];
            else
                [db commit];
        }
    }
    
    if(success)
    {
        [db beginTransaction];
        
        BOOL versionUp =   [db executeUpdate:@"update db_version set version = version + 1 "];
        
        if(!versionUp)
            [db rollback];
        else
            [db commit];
    }
    
    //db version check
    FMResultSet *rs2 = [db executeQuery:@"select max(version) as version from db_version"];
    
    int currentAppDbVersion2 = 0;
    while ([rs2 next]) {
        currentAppDbVersion2 = [rs2 intForColumn:@"version"];
    }
    
    //DDLogVerbose(@"newDatabaseVersion %d [%@-%@]",newDatabaseVersion,THIS_FILE,THIS_METHOD);
    //DDLogVerbose(@"db version check = currentAppDbVersion %d [%@-%@]",currentAppDbVersion2,THIS_FILE,THIS_METHOD);
    
    return success;
}

- (void)alertMessageWithMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Comress" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
}

- (NSDate *)createNSDateWithWcfDateString:(NSString *)dateString
{
    NSInteger offset = [[NSTimeZone defaultTimeZone] secondsFromGMT]; //get number of seconds to add or subtract according to the client default time zone
    NSInteger startPosition = [dateString rangeOfString:@"("].location + 1; //start of the date value
    NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
    NSDate *date = [[NSDate dateWithTimeIntervalSince1970:unixTime] dateByAddingTimeInterval:offset];
    
    return date;
}


@end
