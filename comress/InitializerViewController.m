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

    [self checkBlockCount];
}

- (void)initializingComplete
{
    DDLogVerbose(@"initializingComplete");
    
    myDatabase.initializingComplete = 1;

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
                    //clear the blocks to sync with new block count
                    BOOL qDelBlocks = [theDb executeUpdate:@"delete from blocks"];
                    
                    if(!qDelBlocks)
                    {
                        *rollback = YES;
                        return;
                    }
                    else
                    {
                        needToDownloadBlocks = YES;
                    }
                }
                else
                {
                    [self initializingComplete];
                }
            }
        }];
        
        if(needToDownloadBlocks)
            [self startDownloadBlocksForPage:1 totalPage:0 requestDate:nil];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingComplete];
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
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_blocks] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"BlockContainer"];
        
        int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
        __block BOOL needToDownload = NO;
        
        //save block count
        [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
            FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from post"];
            
            while ([rsBlockCount next]) {
                int total = [rsBlockCount intForColumn:@"total"];
                
                if(total < totalRows)
                {
                    //clear the blocks to sync with new block count
                    BOOL qDelBlocks = [theDb executeUpdate:@"delete from post"];
                    
                    if(!qDelBlocks)
                    {
                        *rollback = YES;
                        return;
                    }
                    else
                    {
                        needToDownload = YES;
                    }
                }
                else
                {
                    [self initializingComplete];
                }
            }
        }];
        
        if(needToDownload)
            [self startDownloadPostForPage:1 totalPage:0 requestDate:nil];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingComplete];
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
                else
                {
                    [self initializingComplete];
                }
            }
        }];
        
        if(needToDownload)
            [self startDownloadCommentsForPage:1 totalPage:0 requestDate:nil];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingComplete];
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

- (void)startDownloadCommentsForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
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
            [self startDownloadCommentsForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            [comments updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
            
            [self initializingComplete];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingComplete];
    }];
}

- (void)startDownloadPostForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
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
            NSString *ActionStatus = [dictPost valueForKey:@""];
            NSString *BlkId = [dictPost valueForKey:@""];
            NSString *Level = [dictPost valueForKey:@""];
            NSString *Location = [dictPost valueForKey:@""];
            NSString *PostBy = [dictPost valueForKey:@""];
            NSNumber *PostId = [NSNumber numberWithInt:[[dictPost valueForKey:@""] intValue]];
            NSString *PostTopic = [dictPost valueForKey:@""];
            NSString *PostType = [dictPost valueForKey:@""];
            NSString *PostalCode = [dictPost valueForKey:@""];
            NSString *Severity = [dictPost valueForKey:@""];
            NSDate *PostDate = [myDatabase createNSDateWithWcfDateString:[dictPost valueForKey:@""]];
            
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
            [self startDownloadPostForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            [posts updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
            
            [self initializingComplete];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingComplete];
    }];
}

- (void)startDownloadBlocksForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
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
            [self startDownloadBlocksForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            [blocks updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            self.processLabel.text = @"Download complete";
            
            //check for comments
            [self checkCommentCount];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self initializingComplete];
    }];
}



@end
