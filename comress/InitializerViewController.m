//
//  InitializerViewController.m
//  comress
//
//  Created by Diffy Romano on 12/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "InitializerViewController.h"

@interface InitializerViewController ()
{
 
}
@end

@implementation InitializerViewController

@synthesize imagesDict;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    myAfManager = [AFManager sharedMyAfManager];
    
    databaseQueue = [FMDatabaseQueue databaseQueueWithPath:myDatabase.dbPath];
    db = [myDatabase prepareDatabaseFor:self];
    
    blocks = [[Blocks alloc] init];
    posts = [[Post alloc] init];
    comments = [[Comment  alloc] init];
    postImage = [[PostImage alloc] init];
    comment_noti = [[Comment_noti alloc] init];

    [self checkBlockCount];
}

- (void)initializingCompleteWithUi:(BOOL)withUi
{
    myDatabase.initializingComplete = 1;
    
    //start interval download of new posts
    [[NSNotificationCenter defaultCenter] postNotificationName:@"postDownloadFinish" object:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"postImageDownloadFinish" object:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"commentDownloadFinish" object:nil];
    
    if(withUi)
        [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - check if we need to sync blocks
- (void)checkBlockCount
{
    NSDate *last_request_date = nil;
    
    FMResultSet *rs = [db executeQuery:@"select date from blocks_last_request_date"];
    while ([rs next]) {
        last_request_date = [rs dateForColumn:@"date"];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(last_request_date != nil)
    {
        jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
    }
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_blocks] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"BlockContainer"];
        
        int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
        __block BOOL needToDownloadBlocks = NO;
        
        //save block count
        [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
            FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from blocks"];
            
            while ([rsBlockCount next]) {
                int total = [rsBlockCount intForColumn:@"total"];
                
                if(total < totalRows)
                {
                    needToDownloadBlocks = YES;
                }
            }
        }];
        
        if(needToDownloadBlocks)
            [self startDownloadBlocksForPage:1 totalPage:0 requestDate:nil withUi:YES];
        else
            [self checkPostCount];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:YES];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - check if we need to sync blocks
- (void)checkPostCount
{
    NSDate *last_request_date = nil;
    
    FMResultSet *rs = [db executeQuery:@"select date from post_last_request_date"];
    while ([rs next]) {
        last_request_date = [rs dateForColumn:@"date"];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(last_request_date != nil)
    {
        jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
    }
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_posts] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"PostContainer"];
        
        int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
        __block BOOL needToDownload = NO;
        
        //save block count
        [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
            FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from post"];
            
            while ([rsBlockCount next]) {
                int total = [rsBlockCount intForColumn:@"total"];
                
                if(total < totalRows)
                {
                   needToDownload = YES;
                }
            }
        }];
        
        if(needToDownload)
            [self startDownloadPostForPage:1 totalPage:0 requestDate:nil withUi:YES];
        else
            [self checkCommentCount];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:YES];
    }];
}

#pragma mark - check if we need to sync blocks
- (void)checkCommentCount
{
    NSDate *last_request_date = nil;
    
    FMResultSet *rs = [db executeQuery:@"select date from comment_last_request_date"];
    while ([rs next]) {
        last_request_date = [rs dateForColumn:@"date"];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(last_request_date != nil)
    {
        jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
    }
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_comments] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"CommentContainer"];
        
        int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
        __block BOOL needToDownload = NO;
        
        //save block count
        [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
            FMResultSet *rsCount = [theDb executeQuery:@"select count(*) as total from comment"];
            
            while ([rsCount next]) {
                int total = [rsCount intForColumn:@"total"];
                DDLogVerbose(@"total %d, totalRows %d",total,totalRows);
                if(total < totalRows)
                {
                    needToDownload = YES;
                }
            }
        }];
        
        if(needToDownload)
            [self startDownloadCommentsForPage:1 totalPage:0 requestDate:nil withUi:YES];
        else
            [self checkPostImagesCount];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:YES];
    }];
}

#pragma mark - download post images
-(void)checkPostImagesCount
{
    imgOpts = [ImageOptions new];
    
    NSDate *last_request_date = nil;
    
    FMResultSet *rs = [db executeQuery:@"select date from post_image_last_request_date"];
    while ([rs next]) {
        last_request_date = [rs dateForColumn:@"date"];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(last_request_date != nil)
    {
        jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
    }
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_images] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"ImageContainer"];
        
        int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
        __block BOOL needToDownload = NO;
        
        //save block count
        [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
            FMResultSet *rsCount = [theDb executeQuery:@"select count(*) as total from post_image"];
            
            while ([rsCount next]) {
                int total = [rsCount intForColumn:@"total"];
                DDLogVerbose(@"total %d, totalRows %d",total,totalRows);
                if(total < totalRows)
                {
                    needToDownload = YES;
                }
            }
        }];
        
        if(needToDownload)
            [self startDownloadPostImagesForPage:1 totalPage:0 requestDate:nil withUi:YES];
        else
            [self checkCommentNotiCount];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:YES];
    }];
}

#pragma mark - check comment noti
-(void)checkCommentNotiCount
{
    NSDate *last_request_date = nil;
    
    FMResultSet *rs = [db executeQuery:@"select date from comment_noti_last_request_date"];
    while ([rs next]) {
        last_request_date = [rs dateForColumn:@"date"];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(last_request_date != nil)
    {
        jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
    }
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_comment_noti] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"CommentNotiContainer"];
        
        int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
        __block BOOL needToDownload = NO;
        
        //save block count
        [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
            FMResultSet *rsCount = [theDb executeQuery:@"select count(*) as total from comment_noti"];
            
            while ([rsCount next]) {
                int total = [rsCount intForColumn:@"total"];
                DDLogVerbose(@"total %d, totalRows %d",total,totalRows);
                if(total < totalRows)
                {
                    needToDownload = YES;
                }
            }
        }];
        
        if(needToDownload)
            [self startDownloadCommentNotiForPage:1 totalPage:0 requestDate:nil withUi:YES];
        else
            [self initializingCompleteWithUi:YES];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:YES];
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (void)startDownloadCommentNotiForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading notifications page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_images] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"CommentNotiContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        DDLogVerbose(@"%@",LastRequestDate);
        //prepare to download the blocks!
        NSArray *dictArray = [dict objectForKey:@"CommentNotiList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictNoti = [dictArray objectAtIndex:i];
            
            NSNumber *CommentId = [NSNumber numberWithInt:[[dictNoti valueForKey:@"CommentId"] intValue]];
            NSString *UserId = [dictNoti valueForKey:@"UserId"];
            NSNumber *PostId = [NSNumber numberWithInt:[[dictNoti valueForKey:@"PostId"] intValue]];
            NSNumber *Status = [NSNumber numberWithInt:[[dictNoti valueForKey:@"Status"] intValue]];

            
            [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                BOOL qIns = [theDb executeUpdate:@"insert into comment_noti(comment_id, user_id, post_id, status) values(?,?,?,?)",CommentId,UserId,PostId,Status];
                
                if(!qIns)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadCommentNotiForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [comment_noti updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:withUi];
    }];
}

- (void)startDownloadPostImagesForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading images page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_images] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"ImageContainer"];
        imagesDict = dict;
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadPostImagesForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            [self SavePostImagesToDb];
        }
        

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:withUi];
    }];
}


- (void)SavePostImagesToDb
{
    NSArray *imagesArray = [imagesDict objectForKey:@"ImageList"];
    
    if (imagesArray.count > 0) {
        for (int i = 0; i < imagesArray.count; i++) {
            
            NSDictionary *dict = (NSDictionary *)[imagesArray objectAtIndex:i];
            
            NSNumber *CommentId = [NSNumber numberWithInt:[[dict valueForKey:@"CommentId"] intValue]];
            NSNumber *ImageType = [NSNumber numberWithInt:[[dict valueForKey:@"ImageType"] intValue]];
            NSNumber *PostId = [NSNumber numberWithInt:[[dict valueForKey:@"PostId"] intValue]];
            NSNumber *PostImageId = [NSNumber numberWithInt:[[dict valueForKey:@"PostImageId"] intValue]];
            NSString *ImagePath = [dict valueForKey:@"ImagePath"];
//            ImagePath = @"https://harveyblackauthor.files.wordpress.com/2012/06/tiger-tank-017.jpg";
            SDWebImageManager *sd_manager = [SDWebImageManager sharedManager];
            
            [sd_manager downloadImageWithURL:[NSURL URLWithString:ImagePath] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {

                NSInteger percentage = 100 / (expectedSize / receivedSize);
                
                self.processLabel.text = [NSString stringWithFormat:@"Downloading image. %ld%%",(long)percentage];
                
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                
                //create the image here
                NSData *jpegImageData = UIImageJPEGRepresentation(image, 1);
                
                //save the image to app documents dir
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsPath = [paths objectAtIndex:0];
                NSString *imageFileName = [NSString stringWithFormat:@"%@.jpg",[[NSUUID UUID] UUIDString]];
                
                NSString *filePath = [documentsPath stringByAppendingPathComponent:imageFileName]; //Add the file name
                [jpegImageData writeToFile:filePath atomically:YES];
                
                //resize the saved image
                [imgOpts resizeImageAtPath:filePath];
                
                [db beginTransaction];
                
                BOOL qIns = [db executeUpdate:@"insert into post_image(comment_id, image_type, post_id, post_image_id, image_path) values(?,?,?,?,?)",CommentId,ImageType,PostId,PostImageId,imageFileName];
                
                if(!qIns)
                    [db rollback];
                else
                {
                    [db commit];
                    DDLogVerbose(@"commit!");
                    
                }
                
                if(imagesArray.count-1 == i) //last object
                {
                    DDLogVerbose(@"image count %lu, current index %d",(unsigned long)imagesArray.count,i);
                    
                    [postImage updateLastRequestDateWithDate:[imagesDict valueForKey:@"LastRequestDate"]];
                    
                    self.processLabel.text = @"Download complete";
                    
                    [self checkCommentNotiCount];
                }
                
            }];
        }
    }
    else
    {
        [self checkCommentNotiCount];
    }
}

- (void)startDownloadCommentsForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading comments page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
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
                BOOL qIns = [theDb executeUpdate:@"insert into comment (comment_by, comment_id, comment, comment_type, post_id, comment_on) values (?,?,?,?,?,?)",CommentBy,CommentId,CommentString,CommentType,PostId,CommentDate];
                
                if(!qIns)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadCommentsForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [comments updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
            
            [self checkPostImagesCount];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:withUi];
    }];
}

- (void)startDownloadPostForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading posts page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_posts] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"PostContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        DDLogVerbose(@"%@",LastRequestDate);
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

            [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                BOOL qIns = [theDb executeUpdate:@"insert into post (status, block_id, level, address, post_by, post_id, post_topic, post_type, postal_code, severity, post_date) values (?,?,?,?,?,?,?,?,?,?,?)",ActionStatus, BlkId, Level, Location, PostBy, PostId, PostTopic, PostType, PostalCode, Severity, PostDate];
                
                if(!qIns)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadPostForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [posts updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
            
            [self checkCommentCount];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:withUi];
    }];
}

- (void)startDownloadBlocksForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];


    self.processLabel.text = [NSString stringWithFormat:@"Downloading blocks page... %d/%d",currentPage,totPage];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_blocks] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"BlockContainer"];

        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        DDLogVerbose(@"%@",LastRequestDate);
        //prepare to download the blocks!
        NSArray *dictArray = [dict objectForKey:@"BlockList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictBlock = [dictArray objectAtIndex:i];
            NSNumber *BlkId = [NSNumber numberWithInt:[[dictBlock valueForKey:@"BlkId"] intValue]];
            NSString *BlkNo = [dictBlock valueForKey:@"BlkNo"];
            NSNumber *IsOwnBlk = [NSNumber numberWithInt:[[dictBlock valueForKey:@"IsOwnBlk"] intValue]];
            NSString *PostalCode = [dictBlock valueForKey:@"PostalCode"];
            NSString *StreetName = [dictBlock valueForKey:@"StreetName"];
            
            [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                BOOL qBlockIns = [theDb executeUpdate:@"insert into blocks (block_id, block_no, is_own_block, postal_code, street_name) values (?,?,?,?,?)",BlkId,BlkNo,IsOwnBlk,PostalCode,StreetName];
                
                if(!qBlockIns)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadBlocksForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [blocks updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
            
            //check for posts
            [self checkPostCount];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingCompleteWithUi:withUi];
    }];
}



@end
