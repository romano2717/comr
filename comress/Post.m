//
//  Post.m
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Post.h"

@implementation Post

@synthesize
client_post_id,
post_id,
post_topic,
post_by,
post_date,
post_type,
severity,
address,
status,
level,
block_id,
postal_code,
last_request_date
;

-(id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
        db = [myDatabase prepareDatabaseFor:self];
        databaseQueue = [FMDatabaseQueue databaseQueueWithPath:myDatabase.dbPath];
        
        last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from post_last_request_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
    }
    return self;
}

- (long long)savePostWithDictionary:(NSDictionary *)dict
{
    BOOL postSaved;
    long long posClienttId = 0;
    
    client_post_id  = [[dict valueForKey:@"client_post_id"] intValue];
    post_id         = [[dict valueForKey:@"post_id"] intValue];
    post_topic      = [dict valueForKey:@"post_topic"];
    post_by         = [dict valueForKey:@"post_by"];
    post_date       = [dict valueForKey:@"post_date"];
    post_type       = [dict valueForKey:@"post_type"];
    severity        = [dict valueForKey:@"severity"];
    address         = [dict valueForKey:@"address"];
    status          = [dict valueForKey:@"status"];
    level           = [dict valueForKey:@"level"];
    block_id        = [dict valueForKey:@"block_id"];
    postal_code     = [dict valueForKey:@"postal_code"];
    
    [db beginTransaction];
    
    postSaved = [db executeUpdate:@"insert into post (post_topic,post_by,post_date,post_type,severity,address,status,level,block_id,isUpdated,postal_code) values (?,?,?,?,?,?,?,?,?,?,?)",post_topic,post_by,post_date,post_type,severity,address,status,level,[NSNumber numberWithInt:1],[NSNumber numberWithBool:YES],postal_code];
    
    if(!postSaved)
    {
        [db rollback];
        DDLogVerbose(@"%@ [%@-%@]",[db lastError],THIS_FILE,THIS_METHOD);
    }
    
    else
    {
        [db commit];
        posClienttId = [db lastInsertRowId];
    }
    
    return posClienttId;
}

- (void)close
{
    [db close];
}

- (NSArray *)fetchIssuesWithParams:(NSDictionary *)params forPostId:(NSNumber *)postId
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    client_post_id      = [[params valueForKey:@"client_post_id"] intValue];
    post_id             = [[params valueForKey:@"post_id"] intValue];
    post_topic          = [params valueForKey:@"post_topic"];
    post_by             = [params valueForKey:@"post_by"];
    post_date           = [params valueForKey:@"post_date"];
    post_type           = [params valueForKey:@"post_type"];
    severity            = [params valueForKey:@"severity"];
    address             = [params valueForKey:@"address"];
    status              = [params valueForKey:@"status"];
    level               = [params valueForKey:@"level"];

    NSString *orderBy   = [params valueForKey:@"orderBy"];
    NSString *limit     = [params valueForKey:@"limit"];
    
    /*
     change query to also get all the images for the post
     */
    NSMutableString *q;
    
    if(postId == nil)
        q = [[NSMutableString alloc] initWithString:@"select * from post "];
    else
        q = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"select * from post where client_post_id = %@ ",postId]];
    
    if([params valueForKey:@"order"])
    {
        [q appendString:[params valueForKey:@"order"]];
    }
    
    FMResultSet *rsPost = [db executeQuery:q];
    
    while ([rsPost next]) {
        
        NSNumber *postId = [NSNumber numberWithInt:[rsPost intForColumn:@"client_post_id"]];
        
        NSMutableDictionary *postDict = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *postChild = [[NSMutableDictionary alloc] init];
        
        //add post info to our dict. this will be the top most level of our dictionary entry
        [postChild setObject:[rsPost resultDictionary] forKey:@"post"];
        

        //add all images of this post
        FMResultSet *rsPostImage = [db executeQuery:@"select * from post_image where client_post_id = ? and client_comment_id is null order by client_post_image_id ",postId];
        NSMutableArray *imagesArray = [[NSMutableArray alloc] init];
        
        while ([rsPostImage next]) {
            [imagesArray addObject:[rsPostImage resultDictionary]];
        }
        
        [postChild setObject:imagesArray forKey:@"postImages"];
        
        
        //get all comments for this post including comment image if there's any
        FMResultSet *rsPostComment = [db executeQuery:@"select * from comment where client_post_id = ? order by comment_on asc",postId];
        NSMutableArray *commentsArray = [[NSMutableArray alloc] init];

        while ([rsPostComment next]) {
            
            NSMutableDictionary *commentsDict = [[NSMutableDictionary alloc] initWithDictionary:[rsPostComment resultDictionary]];
            
            if([[rsPostComment stringForColumn:@"comment"] isEqualToString:@"<image>"])
            {
                //get the image path
                FMResultSet *rsImagePath = [db executeQuery:@"select image_path from post_image where client_comment_id = ?",[NSNumber numberWithInt:[rsPostComment intForColumn:@"client_comment_id"]]];
                
                while ([rsImagePath next]) {
                    [commentsDict setObject:[rsImagePath stringForColumn:@"image_path"] forKey:@"image"];
                }
            }
            
            [commentsArray addObject:commentsDict];
            
        }
        
        [postChild setObject:commentsArray forKey:@"postComments"];
        
        
        [postDict setObject:postChild forKey:postId];
        
        
        [arr addObject:postDict];
    }
    
    return arr;
}

- (NSArray *)postsToSend
{
    FMResultSet *rs = [db executeQuery:@"select * from post where post_id IS NULL or post_id = ?",[NSNumber numberWithInt:0]];

    NSMutableArray *rsArray = [[NSMutableArray alloc] init];
    
    while ([rs next]) {
        
        NSDictionary *dict = @{
                               @"PostTopic":[rs stringForColumn:@"post_topic"],
                               @"PostBy":[rs stringForColumn:@"post_by"],
                               @"PostType":[rs stringForColumn:@"post_type"],
                               @"Severity":[rs stringForColumn:@"severity"],
                               @"ActionStatus":[rs stringForColumn:@"status"],
                               @"ClientPostId":[NSNumber numberWithInt:[rs intForColumn:@"client_post_id"]],
                               @"BlkId":[NSNumber numberWithInt:[rs intForColumn:@"block_id"]],
                               @"Location":[rs stringForColumn:@"address"],
                               @"PostalCode":[rs stringForColumn:@"postal_code"],
                               @"Level":[rs stringForColumn:@"level"],
                               @"IsUpdated":[NSNumber numberWithBool:NO]
                               };
        
        
        [rsArray addObject:dict];
        
        dict = nil;
    }

    return rsArray;
}

- (BOOL)updatePostStatusForClientPostId:(NSNumber *)clientPostId withStatus:(NSNumber *)theStatus
{
    [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        BOOL upPost = [theDb executeUpdate:@"update post set status = ? where client_post_id = ?",theStatus,clientPostId];
        
        if(!upPost)
        {
            *rollback = YES;
            return ;
        }
    }];
    
    return NO;
}

@end
