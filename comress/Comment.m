//
//  Comment.m
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Comment.h"

@implementation Comment

@synthesize
client_comment_id,
comment_id,
client_post_id,
post_id,
comment,
comment_on,
comment_by,
comment_type
;

-(id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
        db = [myDatabase prepareDatabaseFor:self];
        
        databaseQueue = [FMDatabaseQueue databaseQueueWithPath:myDatabase.dbPath];
        
    }
    return self;
}

- (BOOL)saveCommentWithDict:(NSDictionary *)dict
{
    __block BOOL ok = YES;
    
    if([[dict valueForKey:@"messageType"] isEqualToString:@"text"])
    {
        
        if([[dict valueForKey:@"comment_type"] intValue] == 1 || [[dict valueForKey:@"comment_type"] intValue] == 2)
        {
            [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                BOOL qComment = [theDb executeUpdate:@"insert into comment (client_post_id, comment, comment_on, comment_by, comment_type) values (?,?,?,?,?)",[NSNumber numberWithInt:[[dict valueForKey:@"client_post_id"] intValue]], [dict valueForKey:@"text"], [dict valueForKey:@"date"], [dict valueForKey:@"senderId"], [dict valueForKey:@"comment_type"]];
                
                if(!qComment)
                {
                    ok = NO;
                    *rollback = YES;
                    return;
                }
            }];
            
        }
    }
    else //comment with image
    {
        [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
            
            BOOL qComment2 = [theDb executeUpdate:@"insert into comment (client_post_id, comment, comment_on, comment_by, comment_type) values (?,?,?,?,?)",[NSNumber numberWithInt:[[dict valueForKey:@"client_post_id"] intValue]], @"<image>", [dict valueForKey:@"date"], [dict valueForKey:@"senderId"], [dict valueForKey:@"comment_type"]];
            
            if(!qComment2)
            {
                ok = NO;
                *rollback = YES;
                return;
            }
            
            else
            {
                imgOpts = [ImageOptions new];
                
                //save the image to docs dir & post_image table
                
                UIImage *image = [dict valueForKey:@"image"];
                
                NSData *jpegImageData = UIImageJPEGRepresentation(image, 1);
                
                //save the image to app documents dir
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsPath = [paths objectAtIndex:0];
                NSString *imageFileName = [NSString stringWithFormat:@"%@.jpg",[[NSUUID UUID] UUIDString]];

                NSString *filePath = [documentsPath stringByAppendingPathComponent:imageFileName]; //Add the file name
                [jpegImageData writeToFile:filePath atomically:YES];
                
                //resize the saved image
                [imgOpts resizeImageAtPath:filePath];
                
                long long lastClientCommentId = [theDb lastInsertRowId];
                
                BOOL qPostImage = [theDb executeUpdate:@"insert into post_image (client_post_id, client_comment_id,image_path,status,downloaded,image_type)values (?,?,?,?,?,?)",[NSNumber numberWithInt:[[dict valueForKey:@"client_post_id"] intValue]],[NSNumber numberWithLongLong:lastClientCommentId],imageFileName,@"new",@"yes",[NSNumber numberWithInt:2]];
                
                if(!qPostImage)
                {
                    *rollback = YES;
                    return;
                }
            }
        }];
    }
    
    return ok;
}

- (NSDictionary *)commentsToSend
{
    NSNumber *zero = [NSNumber numberWithInt:0];
    
    
    //update comment and post relationship first
    FMResultSet *rsComment = [db executeQuery:@"select * from comment where post_id is null or post_id = ? and comment",zero];
    
    while ([rsComment next]) {
        
        NSNumber *comment_client_post_id = [NSNumber numberWithInt:[rsComment intForColumn:@"client_post_id"]];
        
        FMResultSet *rsPost = [db executeQuery:@"select * from post where client_post_id = ?",comment_client_post_id];
        
        while ([rsPost next]) {
            NSNumber *post_client_id = [NSNumber numberWithInt:[rsPost intForColumn:@"post_id"]];
            
            [db beginTransaction];
            BOOL commentUpQ = [db executeUpdate:@"update comment set post_id = ? where client_post_id = ?",post_client_id,comment_client_post_id];
            
            if(!commentUpQ)
                [db rollback];
            else
                [db commit];
        }
    }
    
    
    
    //prepare comments for sending
    NSMutableArray *commentListArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *commentListDict = [[NSMutableDictionary alloc] init];
    
    FMResultSet *rs = [db executeQuery:@"select * from comment where comment_id  is null or comment_id = ?",zero];
    
    while ([rs next]) {
        
        //{ "ClientCommentId": "1" , "PostId" : "1" ,"CommentString" : "comment 1" , "CommentBy" : "SUP2" , "CommentType" : "1"}
        
        NSNumber *ClientCommentId = [NSNumber numberWithInt:[rs intForColumn:@"client_comment_id"]];
        NSNumber *postId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
        NSString *CommentString = [rs stringForColumn:@"comment"];
        NSString *CommentBy = [rs stringForColumn:@"comment_by"];
        NSString *CommentType = [rs stringForColumn:@"comment_type"];
        
        NSDictionary *dict = @{ @"ClientCommentId": ClientCommentId , @"PostId" : postId ,@"CommentString" : CommentString , @"CommentBy" : CommentBy , @"CommentType" : CommentType};
        
        [commentListArray addObject:dict];
        
        dict = nil;
    }
    
    if(commentListArray.count == 0)
        return nil;
    
    [commentListDict setObject:commentListArray forKey:@"commentList"];
    
    return commentListDict;
}


- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString
{
    NSInteger startPosition = [dateString rangeOfString:@"("].location + 1; //start of the date value
    NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        FMResultSet *rs = [theDb executeQuery:@"select * from comment_last_request_date"];
        
        if(![rs next])
        {
            BOOL qIns = [theDb executeUpdate:@"insert into comment_last_request_date(date) values(?)",date];
            
            if(!qIns)
            {
                *rollback = YES;
                return;
            }
        }
        else
        {
            BOOL qUp = [theDb executeUpdate:@"update comment_last_request_date set date = ? ",date];
            
            if(!qUp)
            {
                *rollback = YES;
                return;
            }
        }
    }];
    
    return YES;
}


@end
