//
//  Synchronize.m
//  comress
//
//  Created by Diffy Romano on 9/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Synchronize.h"

@implementation Synchronize

-(id)init {
    if (self = [super init]) {
        
        myAfManager = [AFManager sharedMyAfManager];
        myDatabase = [Database sharedMyDbManager];
        databaseQueue = [FMDatabaseQueue databaseQueueWithPath:myDatabase.dbPath];
    }
    return self;
}

+(id)sharedManager {
    static Synchronize *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)uploadPostStatusChange
{
    [databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
       
        FMResultSet *rs = [db executeQuery:@"select * from post where statusWasUpdate = ?",[NSNumber numberWithBool:YES]];
        
        if([rs next])
        {
            DDLogVerbose(@"upload post status for post_id %d, client_post_id %d",[rs intForColumn:@"post_id"],[rs intForColumn:@"client_post_id"]);
        }
        
    }];
}

- (void)uploadPost
{
    __block Post *post = [[Post alloc] init];
 
    NSArray *array = [post postsToSend];
    
    if(array.count == 0)
        return;
    
    NSMutableArray *postListArray     = [[NSMutableArray alloc] init];
    NSMutableDictionary *postListDict = [[NSMutableDictionary alloc] init];
    
    for (int i = 0; i < array.count; i++) {
        NSDictionary *dict = [array objectAtIndex:i];
        
        [postListArray addObject:dict];
        
        dict = nil;
    }

    [postListDict setObject:postListArray forKey:@"postList"];
    DDLogVerbose(@"%@",postListDict);
    
    if(postListArray.count == 0)
        return;

    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_post_send] parameters:postListDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = (NSDictionary *)responseObject;
        DDLogVerbose(@"response dict %@",dict);
        NSArray *arr = [dict objectForKey:@"AckPostObj"];

        for (int i = 0; i < arr.count; i++) {
            
            NSDictionary *dict = [arr objectAtIndex:i];
            
            NSNumber *clientPostId = [dict valueForKey:@"ClientPostId"];
            NSNumber *postId = [dict valueForKey:@"PostId"];
            
            databaseQueue = [FMDatabaseQueue databaseQueueWithPath:myDatabase.dbPath];
            
            [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
               
                [theDb  executeUpdate:@"update post set post_id = ? where client_post_id = ?",postId, clientPostId];
                
                BOOL qPostImage = [theDb executeUpdate:@"update post_image set post_id = ? where client_post_id = ?",postId, clientPostId];
                
                if(!qPostImage)
                {
                    *rollback = YES;
                    return;
                }
                
                BOOL qComment = [theDb executeUpdate:@"update comment set post_id = ? where client_post_id = ?",postId, clientPostId];
                
                if(!qComment)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        post = nil;

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}


- (void)uploadComment
{
    __block Comment *comment = [[Comment alloc] init];
    
    NSDictionary *dict = [comment commentsToSend];

    if(dict == nil)
        return;
    
    DDLogVerbose(@"%@",dict);
    
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_comment_send] parameters:dict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSArray *arr = [responseObject objectForKey:@"AckCommentObj"];

        for(int i = 0; i < arr.count; i++)
        {
            NSDictionary *dict = [arr objectAtIndex:i];
            
            NSNumber *clientCommentId = [NSNumber numberWithInt:[[dict valueForKey:@"ClientCommentId"] intValue]];
            NSNumber *commentId = [NSNumber numberWithInt:[[dict valueForKey:@"CommentId"] intValue]];
            
            databaseQueue = [FMDatabaseQueue databaseQueueWithPath:myDatabase.dbPath];
            
            [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
               
                BOOL qComment = [theDb executeUpdate:@"update comment set comment_id = ? where client_comment_id = ?",commentId,clientCommentId];
                if(!qComment)
                {
                    *rollback = YES;
                    return;
                }
                
                BOOL qCommentImage = [theDb executeUpdate:@"update post_image set comment_id = ? where client_comment_id = ?",commentId,clientCommentId];
                if(!qCommentImage)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        comment = nil;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}

- (void)uploadImage
{
    __block PostImage *postImage = [[PostImage alloc] init];
    
    NSDictionary *dict = [postImage imagesTosend];
    
    if(dict == nil)
        return;

    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_send_images] parameters:dict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSArray *arr = [responseObject objectForKey:@"AckPostImageObj"];
        
        DDLogVerbose(@"AckPostImageObj %@",arr);
        
        for (int i = 0; i < arr.count; i++) {
            NSDictionary *dict = [arr objectAtIndex:i];
            
            NSNumber *ClientPostImageId = [NSNumber numberWithInt:[[dict valueForKey:@"ClientPostImageId"] intValue]];
            NSNumber *PostImageId = [NSNumber numberWithInt:[[dict valueForKey:@"PostImageId"] intValue]];
            
            [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                BOOL qPostImage = [theDb executeUpdate:@"update post_image set post_image_id = ?, uploaded = ? where client_post_image_id = ?  ",PostImageId,@"YES",ClientPostImageId];
                
                if(!qPostImage)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        postImage = nil;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}



















- (NSDate *)deserializeJsonDateString: (NSString *)jsonDateString
{
    NSInteger offset = [[NSTimeZone defaultTimeZone] secondsFromGMT]; //get number of seconds to add or subtract according to the client default time zone
    
    NSInteger startPosition = [jsonDateString rangeOfString:@"("].location + 1; //start of the date value
    //NSInteger startPosition = [jsonDateString rangeOfString:@"("].location ;
    
    NSTimeInterval unixTime = [[jsonDateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
    
    NSDate *date =  [[NSDate dateWithTimeIntervalSince1970:unixTime] dateByAddingTimeInterval:offset];
    
    return date;
}
@end
