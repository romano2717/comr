//
//  SettingsViewController.m
//  comress
//
//  Created by Diffy Romano on 2/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize userFullNameLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    db = [myDatabase prepareDatabaseFor:self];
    myAfManager = [AFManager sharedMyAfManager];
    
    users = [[Users alloc] init];
    client = [[Client alloc] init];
    
    //get user profile
    FMResultSet *rs = [db executeQuery:@"select user_guid from client"];
    if([rs next])
    {
        FMResultSet *rs2 = [db executeQuery:@"select * from users where guid = ?",[rs stringForColumn:@"user_guid"]];
        
        if([rs2 next])
            userFullNameLabel.text = [rs2 stringForColumn:@"full_name"];
    }
    
    userFullNameLabel.text = users.full_name;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)logout:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Comress" message:@"Are you sure you want to logout?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    alert.tag = 1;
    [alert show];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"modal_login"])
    {
        [segue destinationViewController];
    }
    
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 1)
    {
        if(buttonIndex == 1)
        {
            AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
            [manager GET:[NSString stringWithFormat:@"%@%@%@",myAfManager.api_url,api_logout,client.user_guid] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                NSDictionary *dict = (NSDictionary *)responseObject;
                if([[dict valueForKey:@"Result"] intValue] == 1)
                {
                    BOOL q;
                    
                    [db beginTransaction];
                    q = [db executeUpdate:@"delete from users where guid= ? ",client.user_guid];
                    
                    if(!q)
                    {
                        [db rollback];
                    }
                    else
                    {
                        [db commit];
                        
                        BOOL q2;
                        [db beginTransaction];
                        q2 = [db executeUpdate:@"update client set user_guid = ?",client.user_guid];
                        
                        if(!q2)
                            [db rollback];
                        else
                        {
                            [db commit];
                            
                            if(self.presentingViewController != nil) //the tab was presented modall, dismiss it first.
                            {
                                [self dismissViewControllerAnimated:YES completion:nil];
                                [self.navigationController popToRootViewControllerAnimated:YES];
                            }
                            else //the tab was presented at first launch(user previously logged)
                            {
                                [self dismissViewControllerAnimated:YES completion:nil];
                                [self performSegueWithIdentifier:@"modal_login" sender:self];
                            }
                        }
                    }
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                DDLogVerbose(@"%@ [%@-%@]",error,THIS_FILE,THIS_METHOD);
            }];
        }
    }
}

- (IBAction)reset:(id)sender
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:myDatabase.dbPath];
    
    [queue inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        [theDb executeUpdate:@"delete from client"];
        
        BOOL qComment = [theDb executeUpdate:@"delete from comment"];
        if(!qComment)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qCommentNoti = [theDb executeUpdate:@"delete from comment_noti"];
        if(!qCommentNoti)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qDToken = [theDb executeUpdate:@"delete from device_token"];
        if(!qDToken)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qPost = [theDb executeUpdate:@"delete from post"];
        if(!qPost)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qPostImg = [theDb executeUpdate:@"delete from post_image"];
        if(!qPostImg)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qUser = [theDb executeUpdate:@"delete from users"];
        if(!qUser)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qBlocks = [theDb executeUpdate:@"delete from blocks"];
        if(!qBlocks)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qBlockCount = [theDb executeUpdate:@"delete from blocks_count"];
        [theDb executeUpdate:@"insert into blocks_cout(total) values(?)",[NSNumber numberWithInt:0]];
        
        if(!qBlockCount)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        BOOL qReqDate = [theDb executeUpdate:@"delete from request_date"];
        if(!qReqDate)
        {
            *rollback = YES;
            [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"Reset failed. %@",[theDb lastError]]];
            return;
        }
        
        
    }];
    
    exit(1);
}

@end
