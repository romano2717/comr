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
street_name;

- (id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
        
        databaseQueue = [FMDatabaseQueue databaseQueueWithPath:myDatabase.dbPath];
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

@end
