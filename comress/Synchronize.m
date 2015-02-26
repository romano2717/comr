//
//  Synchronize.m
//  comress
//
//  Created by Diffy Romano on 9/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Synchronize.h"

@implementation Synchronize

@synthesize imagesArray;

-(id)init {
    if (self = [super init]) {
        
        myAfManager = [AFManager sharedMyAfManager];
        myDatabase = [Database sharedMyDbManager];
        databaseQueue = [FMDatabaseQueue databaseQueueWithPath:myDatabase.dbPath];
        
        init = [[InitializerViewController alloc] init];
        
        imagesArray = [[NSMutableArray alloc] init];
        
        blocks = [[Blocks alloc] init];
        post = [[Post alloc] init];
        postImage = [[PostImage alloc] init];
        comment = [[Comment alloc] init];

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
       
        FMResultSet *rs = [db executeQuery:@"select * from post where statusWasUpdated = ?",[NSNumber numberWithBool:YES]];
        
        if([rs next])
        {
            DDLogVerbose(@"upload post status for post_id %d, client_post_id %d",[rs intForColumn:@"post_id"],[rs intForColumn:@"client_post_id"]);
        }
        
    }];
}

#pragma mark - upload new data to server

- (void)uploadPost
{
    __block Post *myPost = [[Post alloc] init];
 
    NSArray *array = [myPost postsToSend];
    
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
        
        myPost = nil;

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}


- (void)uploadComment
{
    __block Comment *myComment = [[Comment alloc] init];
    
    NSDictionary *dict = [myComment commentsToSend];

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
        
        myComment = nil;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}

- (void)uploadImage
{
    __block PostImage *myPostImage = [[PostImage alloc] init];
    
    NSDictionary *dict = [myPostImage imagesTosend];
    
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
        
        myPostImage = nil;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}


#pragma mark - download new data from server
- (void)startDownloadPostForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    DDLogVerbose(@"currentPage %d",currentPage);
    NSString *jsonDate = [self serializedStringDateJson:reqDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    DDLogVerbose(@"params %@",params);
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_posts] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"PostContainer"];

        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
            
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];

        //prepare to download the blocks!
        NSArray *dictArray = [dict objectForKey:@"PostList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictPost = [dictArray objectAtIndex:i];
            
            NSNumber *ActionStatus = [NSNumber numberWithInt:[[dictPost valueForKey:@"ActionStatus"] intValue]];
            NSString *BlkId = [NSString stringWithFormat:@"%d",[[dictPost valueForKey:@"BlkId"] intValue]];
            NSString *Level = [dictPost valueForKey:@"Level"];
            NSString *Location = [dictPost valueForKey:@"Location"];
            NSString *PostBy = [dictPost valueForKey:@"PostBy"];
            NSNumber *PostId = [NSNumber numberWithInt:[[dictPost valueForKey:@"PostId"] intValue]];
            NSString *PostTopic = [dictPost valueForKey:@"PostTopic"];
            NSString *PostType = [NSString stringWithFormat:@"%d",[[dictPost valueForKey:@"PostType"] intValue]];
            NSString *PostalCode = [dictPost valueForKey:@"PostalCode"];
            NSNumber *Severity = [NSNumber numberWithInt:[[dictPost valueForKey:@"Severity"] intValue]];
            NSDate *PostDate = [myDatabase createNSDateWithWcfDateString:[dictPost valueForKey:@"PostDate"]];
            
            DDLogVerbose(@"new post from server %@",dictPost);
            
            [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                FMResultSet *rsPost = [theDb executeQuery:@"select post_id from post where post_id = ?",PostId];
                if([rsPost next] == NO) //does not exist. insert
                {
                    BOOL qIns = [theDb executeUpdate:@"insert into post (status, block_id, level, address, post_by, post_id, post_topic, post_type, postal_code, severity, post_date) values (?,?,?,?,?,?,?,?,?,?,?)",ActionStatus, BlkId, Level, Location, PostBy, PostId, PostTopic, PostType, PostalCode, Severity, PostDate];
                    
                    if(!qIns)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadPostForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            if(dictArray.count > 0)
            {
                [post updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            }
            else
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadIssuesList" object:nil];
            
            // Delay execution of my block for 10 seconds.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"postDownloadFinish" object:nil];
            });
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}


- (void)startDownloadPostImagesForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    NSString *jsonDate = [self serializedStringDateJson:reqDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    DDLogVerbose(@"params %@",params);
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_images] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"ImageContainer"];
        [imagesArray addObject:dict];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadPostImagesForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            if(totalPage > 0)
            {
                [postImage updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
                [self SavePostImagesToDb];
            }
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
}


- (void)SavePostImagesToDb
{
    //NSArray *imagesArray = [imagesDict objectForKey:@"ImageList"];
    
    if (imagesArray.count > 0) {
        for (int i = 0; i < imagesArray.count; i++) {
            
            NSDictionary *dict = (NSDictionary *) [imagesArray objectAtIndex:i];

            NSNumber *CommentId = [NSNumber numberWithInt:[[dict valueForKey:@"CommentId"] intValue]];
            NSNumber *ImageType = [NSNumber numberWithInt:[[dict valueForKey:@"ImageType"] intValue]];
            NSNumber *PostId = [NSNumber numberWithInt:[[dict valueForKey:@"PostId"] intValue]];
            NSNumber *PostImageId = [NSNumber numberWithInt:[[dict valueForKey:@"PostImageId"] intValue]];
            NSString *ImagePath = [dict valueForKey:@"ImagePath"];
            SDWebImageManager *sd_manager = [SDWebImageManager sharedManager];
            
            [sd_manager downloadImageWithURL:[NSURL URLWithString:ImagePath] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                
                //create the image here
                NSData *jpegImageData = UIImageJPEGRepresentation(image, 1);
                
                //save the image to app documents dir
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsPath = [paths objectAtIndex:0];
                NSString *imageFileName = [NSString stringWithFormat:@"%@.jpg",[[NSUUID UUID] UUIDString]];
                
                NSString *filePath = [documentsPath stringByAppendingPathComponent:imageFileName]; //Add the file name
                [jpegImageData writeToFile:filePath atomically:YES];
                
                imgOpts = nil;
                imgOpts = [ImageOptions new];
                
                //resize the saved image
                [imgOpts resizeImageAtPath:filePath];
                
                FMDatabase *db = [myDatabase prepareDatabaseFor:self];
                
                [db beginTransaction];
                
                FMResultSet *rsPostImage = [db executeQuery:@"select post_image_id from post_image where post_image_id = ?",postImage];
                
                if([rsPostImage next] == NO) //does not exist, insert
                {
                    BOOL qIns = [db executeUpdate:@"insert into post_image(comment_id, image_type, post_id, post_image_id, image_path) values(?,?,?,?,?)",CommentId,ImageType,PostId,PostImageId,imageFileName];
                    
                    if(!qIns)
                        [db rollback];
                    else
                    {
                        [db commit];
                        DDLogVerbose(@"commit!");
                        
                    }
                }
                
                [db close];
                
                if(imagesArray.count-1 == i) //last object
                {
                    DDLogVerbose(@"image count %lu, current index %d",(unsigned long)imagesArray.count,i);
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadIssuesList" object:nil];
                    
                    // Delay execution of my block for 10 seconds.
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"postImageDownloadFinish" object:nil];
                    });
                }
                
            }];
        }
    }
    else
    {
        // Delay execution of my block for 10 seconds.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"postImageDownloadFinish" object:nil];
        });
    }
}


- (void)startDownloadCommentsForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    DDLogVerbose(@"currentPage %d",currentPage);
    NSString *jsonDate = [self serializedStringDateJson:reqDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    DDLogVerbose(@"params %@",params);
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_comments] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"CommentContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        DDLogVerbose(@"%@",LastRequestDate);
        //prepare to download the blocks!
        NSArray *dictArray = [dict objectForKey:@"CommentList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictComment = [dictArray objectAtIndex:i];
            
            NSString *CommentBy = [dictComment valueForKey:@"CommentBy"];
            NSNumber *CommentId = [NSNumber numberWithInt:[[dictComment valueForKey:@"CommentId"] intValue]];
            NSString *CommentString = [dictComment valueForKey:@"CommentString"];
            NSNumber *CommentType =  [NSNumber numberWithInt:[[dictComment valueForKey:@"CommentType"] intValue]];
            NSNumber *PostId = [NSNumber numberWithInt:[[dictComment valueForKey:@"PostId"] intValue]];
            NSDate *CommentDate = [myDatabase createNSDateWithWcfDateString:[dictComment valueForKey:@"CommentDate"]];
            
            [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                FMResultSet *rsComment = [theDb executeQuery:@"select comment_id from comment where comment_id = ?",CommentId];
                
                if([rsComment next] == NO) //does not exist, insert
                {
                    BOOL qIns = [theDb executeUpdate:@"insert into comment (comment_by, comment_id, comment, comment_type, post_id, comment_on) values (?,?,?,?,?,?)",CommentBy,CommentId,CommentString,CommentType,PostId,CommentDate];
                    
                    if(!qIns)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadCommentsForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            if(dictArray.count > 0)
            {
                [comment updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadIssuesList" object:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchComments" object:nil];
            }
            
            
            // Delay execution of my block for 10 seconds.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"commentDownloadFinish" object:nil];
            });
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
    }];
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
@end
