//
//  InitializerViewController.m
//  comress
//
//  Created by Diffy Romano on 12/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "InitializerViewController.h"

@interface InitializerViewController ()

@end

@implementation InitializerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    myAfManager = [AFManager sharedMyAfManager];
    
    databaseQueue = [FMDatabaseQueue databaseQueueWithPath:myDatabase.dbPath];
    db = [myDatabase prepareDatabaseFor:self];
    
    [self downloadBlocksForPage:1];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)downloadBlocksForPage2:(int)page
{
    self.processLabel.text = @"Downloading block information...";
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];

    NSDate *date = [NSDate date];
    
    FMResultSet *rsDate = [db executeQuery:@"select max(id),date from request_date"];
    
    while ([rsDate next]) {
        double timeStamp = [rsDate doubleForColumn:@"date"];
        if(timeStamp > 0)
            date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"];
    
    //NSString *jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [date timeIntervalSince1970],[formatter stringFromDate:date]];
    NSString *jsonDate = @"/Date(1420093779+0800)/";

    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};

    __block BOOL blockInsertOk = YES;
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_blocks] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSArray *arr = [[responseObject objectForKey:@"BlockContainer"] objectForKey:@"BlockList"];
        
        //update label
        self.processLabel.text = @"Saving block information...";
        
        for (int i = 0; i < arr.count; i++) {
            
            NSDictionary *dict = [arr objectAtIndex:i];
            
            [db beginTransaction];
            BOOL qClearBlocks = [db executeUpdate:@"delete from blocks"];
            
            if(!qClearBlocks)
            {
                blockInsertOk = NO;
                [db rollback];

            }
            else
                [db commit];
            
            [db beginTransaction];
            BOOL qInsBlock = [db executeUpdate:@"insert into blocks(block_id,block_no,is_own_block,postal_code,street_name) values (?,?,?,?,?)",[dict valueForKey:@"BlkId"],[dict valueForKey:@"BlkNo"],[dict valueForKey:@"IsOwnBlk"],[dict valueForKey:@"PostalCode"],[dict valueForKey:@"StreetName"]];
            
            if(!qInsBlock)
            {
                blockInsertOk = NO;
                [db rollback];
            }
            else
                [db commit];
            
        }
        
        
        //update block count

        NSNumber *count = [NSNumber numberWithInt:(int)arr.count];
        
        [db beginTransaction];
        BOOL qBlockCount = [db executeUpdate:@"update blocks_count set total = ?",count];
        
        if(!qBlockCount)
        {
            [db rollback];
        }
        
        if(blockInsertOk)
        {
            [db commit];
            
            self.processLabel.text = @"Download complete.";
            
            FMResultSet *rsBlocksList = [db executeQuery:@"select * from blocks"];
            while ([rsBlocksList next]) {
                DDLogVerbose(@"new blocks %@",[rsBlocksList resultDictionary]);
            }
            
            //[self dismissViewControllerAnimated:YES completion:nil];
        }

        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        DDLogVerbose(@"%@ [%@-%@]",error,THIS_FILE,THIS_METHOD);
        
    }];
    
}

- (void)downloadBlocksForPage:(int)page
{

    self.processLabel.text = @"Downloading block information...";
    
    NSDate *date = [NSDate date];
    
    FMResultSet *rsDate = [db executeQuery:@"select max(id),date from request_date"];
    
    while ([rsDate next]) {
        double timeStamp = [rsDate doubleForColumn:@"date"];
        if(timeStamp > 0)
            date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"];
    
    //NSString *jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [date timeIntervalSince1970],[formatter stringFromDate:date]];
    NSString *jsonDate = @"/Date(1420093779+0800)/";
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_blocks] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"BlockContainer"];
        NSArray *dictArray = [dict objectForKey:@"BlockList"];
        
        __block BOOL blocksInserted = NO;
        
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
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error,THIS_FILE,THIS_METHOD);
    }];
}

@end
