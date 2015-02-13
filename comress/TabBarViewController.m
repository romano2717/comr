//
//  TabBarViewController.m
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "TabBarViewController.h"
#import "ActivationViewController.h"

@interface TabBarViewController ()
{
    BOOL needToActivate;
    BOOL needToLogin;
}
@end

@implementation TabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSLog(@"tab");
    
    myDatabase = [Database sharedMyDbManager];
    db = [myDatabase prepareDatabaseFor:self];
    myAfManager = [AFManager sharedMyAfManager];
    databaseQueue = [FMDatabaseQueue databaseQueueWithPath:myDatabase.dbPath];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //check for a valid activation code
    NSString *activationCode = nil;
    
    FMResultSet *rs = [db executeQuery:@"select activation_code from client"];
    while([rs next])
    {
        activationCode = [rs stringForColumn:@"activation_code"];
    }
    
    if(activationCode == nil || activationCode.length == 0)
    {
        [self performSegueWithIdentifier:@"modal_activation" sender:self];
        return;
    }
    
    //check for valid login
    FMResultSet *rsClient = [db executeQuery:@"select c.user_guid, u.* from client c, users u where c.user_guid = u.guid"];
    
    if(![rsClient next])
    {
        [self performSegueWithIdentifier:@"modal_login" sender:self];
        return;
    }
    
    else if(!needToActivate && !needToLogin) //init
    {
        [self checkBlockCount];
    }
}

- (void)checkBlockCount
{
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
            }
        }];
        
        if(needToDownloadBlocks)
            [self performSegueWithIdentifier:@"modal_initializer" sender:self];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error,THIS_FILE,THIS_METHOD);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DDLogVerbose(@"tab segue %@",segue.identifier);
    if([segue.identifier isEqualToString:@"modal_activation"])
    {
        [segue destinationViewController];
    }
    
    if([segue.identifier isEqualToString:@"modal_login"])
    {
        [segue destinationViewController];
    }
}


@end
