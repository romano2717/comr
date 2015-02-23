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
        db = [myDatabase prepareDatabaseFor:self];
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

- (void)downloadPost
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_posts] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
       
        DDLogVerbose(@"downloadPost %@",responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}


- (void)downloadComments
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
    
    __block NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    //get comment last request date
    [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        FMResultSet *rs = [theDb executeQuery:@"select date from comment_last_request_date"];
        while([rs next])
        {
            NSDate *lastCommentDate = [rs dateForColumn:@"date"];
            
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [lastCommentDate timeIntervalSince1970],[formatter stringFromDate:lastCommentDate]];
        }
        
    }];
    
    DDLogVerbose(@"%@",jsonDate);
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_comments] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        DDLogVerbose(@"downloadComments %@",responseObject);
        __block BOOL ok = YES;
        NSDictionary *dict = (NSDictionary *)responseObject;
        
        NSArray *top = (NSArray *)[[dict objectForKey:@"CommentContainer"] objectForKey:@"CommentList"];
        NSDate *lastRequestDate = [[dict objectForKey:@"CommentContainer"] valueForKey:@"LastRequestDate"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            for (NSDictionary *obj in top) {
                NSString *CommentBy     = [obj valueForKey:@"CommentBy"];
                NSString *CommentDate   = [obj valueForKey:@"CommentDate"];
                NSNumber *CommentId     = [obj valueForKey:@"CommentId"];
                NSString *CommentString = [obj valueForKey:@"CommentString"];
                NSNumber *CommentType   = [obj valueForKey:@"CommentType"];
                NSNumber *PostId        = [obj valueForKey:@"PostId"];
                
                NSDate *commentDateDate = [self deserializeJsonDateString:CommentDate];
                
                [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                    BOOL save = [theDb executeUpdate:@"insert into comment(comment_by,comment_on,comment_id,comment,comment_type,post_id) values (?,?,?,?,?,?)",CommentBy,commentDateDate,CommentId,CommentString,CommentType,PostId];
                    
                    if(!save)
                    {
                        ok = NO;
                        *rollback = YES;
                    }
                    
                    else
                    {
                        BOOL lrd = NO;
                        
                        FMResultSet *rslrd = [theDb executeQuery:@"select date from comment_last_request_date"];
                        if([rslrd next])
                        {
                            lrd = [theDb executeUpdate:@"update comment_last_request_date set date = ?",lastRequestDate];
                            
                            if(!lrd)
                            {
                                *rollback = YES;
                                return;
                            }
                        }
                        else //add as new
                        {
                            lrd  = [theDb executeUpdate:@"insert into comment_last_request_date(date) values(?)",lastRequestDate];
                        }
                    }
                }];
            }
        });
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}


- (void)downloadPostImages
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
    DDLogVerbose(@" %@",params);
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_images] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        DDLogVerbose(@"downloadPostImages %@",responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}


- (void)downloadCommentNoti
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
    DDLogVerbose(@"%@",params);
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_comment_noti] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        DDLogVerbose(@"downloadCommentNoti %@",responseObject);
        
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
