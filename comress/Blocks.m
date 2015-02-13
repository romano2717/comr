//
//  Blocks.m
//  comress
//
//  Created by Diffy Romano on 12/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Blocks.h"

@implementation Blocks

@synthesize pk_id,
block_id,
block_no,
is_own_block,
postal_code,
street_name,
last_request_date;

- (id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
        databaseQueue = [FMDatabaseQueue databaseQueueWithPath:myDatabase.dbPath];
        
        last_request_date = nil;
        
        [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
            FMResultSet *rs = [theDb executeQuery:@"select date from blocks_last_request_date"];
            while ([rs next]) {
                last_request_date = [rs dateForColumn:@"date"];
            }
        }];
    }
    
    return self;
}

- (NSArray *)fetchBlocksWithBlockId:(NSNumber *)the_block_id
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    if(the_block_id == nil) //return all
    {
        [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
            FMResultSet *rs = [theDb executeQuery:@"select * from blocks"];
            
            while ([rs next]) {
                [arr addObject:[rs resultDictionary]];
            }
        }];
    }
    else
    {
        [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
            FMResultSet *rs = [theDb executeQuery:@"select * from blocks where block_id = ?",the_block_id];
            
            while ([rs next]) {
                [arr addObject:[rs resultDictionary]];
            }
        }];
    }
    
    return arr;
}

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString
{
    NSInteger offset = [[NSTimeZone defaultTimeZone] secondsFromGMT]; //get number of seconds to add or subtract according to the client default time zone
    NSInteger startPosition = [dateString rangeOfString:@"("].location + 1; //start of the date value
    NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
    NSDate *date = [[NSDate dateWithTimeIntervalSince1970:unixTime] dateByAddingTimeInterval:offset];
    
    [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        FMResultSet *rs = [theDb executeQuery:@"select * from blocks_last_request_date"];
        
        if(![rs next])
        {
            BOOL qIns = [theDb executeUpdate:@"insert into blocks_last_request_date(date) values(?)",date];

            if(!qIns)
            {
                *rollback = YES;
                return;
            }
        }
        else
        {
            BOOL qUp = [theDb executeUpdate:@"update blocks_last_request_date set date = ? ",date];
            
            if(!qUp)
            {
                *rollback = YES;
                return;
            }
        }
    }];
    
    return NO;
}

@end
