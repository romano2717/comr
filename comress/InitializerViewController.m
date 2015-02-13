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
    
    [self downloadBlocksForPage:1 totalPage:0];
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

- (void)downloadBlocksForPage:(int)page totalPage:(int)totPage
{
    __block int currentPage = page;
    __block int totalPage = 0;
    __block int totalRows = 0;
    
    self.processLabel.text = [NSString stringWithFormat:@"Downloading blocks page... %d/%d",currentPage,totPage];
    
    NSDate *date = nil;
    
    FMResultSet *rsDate = [db executeQuery:@"select max(id) as max,date from request_date"];
    
    while ([rsDate next]) {
        double timeStamp = [rsDate doubleForColumn:@"date"];
        if([rsDate intForColumn:@"max"] > 0)
            date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"];
    
    NSString *jsonDate = @"/Date(1420093779+0800)/";
    
    if(date != nil)
        jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [date timeIntervalSince1970],[formatter stringFromDate:date]];
    
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    
    AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
    
    [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_download_blocks] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dict = [responseObject objectForKey:@"BlockContainer"];
        
        NSDate *date = [dict valueForKey:@"LastRequestDate"];
        currentPage = [[dict valueForKey:@"CurrentPage"] intValue];
        totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        totalRows = [[dict valueForKey:@"TotalRows"] intValue];
        
        //save block count
        [databaseQueue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
            FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from blocks"];
            while ([rsBlockCount next]) {
                if([rsBlockCount intForColumn:@"total"] < totalRows)
                {
                    //clear the blocks to sync with new block count
                    BOOL qDelBlocks = [theDb executeUpdate:@"delete from blocks"];
                    
                    if(!qDelBlocks)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                else //we have the latest block count. close initializer
                {
                    [self dismissViewControllerAnimated:YES completion:nil];
                    return;
                }
            }
        }];
        
        
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
                
                BOOL qLastReqDate = [theDb executeUpdate:@"insert into request_date(date) values(?)",date];
                
                if(!qLastReqDate)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self downloadBlocksForPage:currentPage totalPage:totalPage];
        }
        else
        {
            self.processLabel.text = @"Download complete";
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error,THIS_FILE,THIS_METHOD);
    }];
}

@end
