//
//  LoginViewController.m
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    myAfManager = [AFManager sharedMyAfManager];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doLogin:(id)sender
{
    NSString *companyId = [self.companyIdTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *userId = [self.userIdTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if(companyId != nil && userId != nil && password != nil && companyId.length > 0 && userId.length > 0 && password.length > 0)
    {
        FMDatabase *db = [myDatabase prepareDatabaseFor:self];
        
        //get user device token
        FMResultSet *rsToken = [db executeQuery:@"select device_token from device_token"];
        NSString *deviceToken;
        
        if(![rsToken next])
        {
            [myDatabase alertMessageWithMessage:@"No Device token found! Please make sure the Notification is enabled for Comress"];
            return;
        }
        else
        {
            deviceToken = [rsToken stringForColumn:@"device_token"];
        }
        
        //get app version
        NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        
        AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
        NSDictionary *params = @{ @"loginUser" : @{@"UserId" : userId, @"CompanyId" : companyId, @"Password" : password, @"DeviceToken" : deviceToken, @"AppVersion" : appVersion, @"OsType" : @"2"}};
        
        DDLogVerbose(@"%@",params);
        
        
        __block BOOL user_q = NO;
        __block BOOL client_q = NO;
        __block BOOL loginOk = YES;
        
        [manager POST:[NSString stringWithFormat:@"%@%@",myAfManager.api_url,api_login] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = (NSDictionary *) responseObject;
            DDLogVerbose(@"%@",dict);
            if([dict objectForKey:@"ActiveUser"] != [NSNull null])
            {
                NSDictionary *ActiveUser = [dict objectForKey:@"ActiveUser"];
                
                NSString *res_CompanyId = [ActiveUser valueForKey:@"CompanyId"];
                NSString *res_UserId = [ActiveUser valueForKey:@"UserId"];
                NSString *res_CompanyName = [ActiveUser valueForKey:@"CompanyName"];
                NSNumber *res_GroupId =  [NSNumber numberWithInt:[[ActiveUser valueForKey:@"GroupId"] intValue]];
                NSString *res_GroupName = [ActiveUser valueForKey:@"GroupName"];
                NSString *res_UserName = [ActiveUser valueForKey:@"UserName"];
                NSString *res_SessionId = [ActiveUser valueForKey:@"SessionId"];
                
                //update/insert user
                FMResultSet *rsUser = [db executeQuery:@"select user_id from users where user_id = ?",res_UserId];
                if([rsUser next])
                {
                    [db beginTransaction];
                    user_q = [db executeUpdate:@"update users set company_id = ?, user_id = ?, company_name = ?, group_id = ?, group_name = ?, full_name = ? guid = ?" ,res_CompanyId,res_UserId,res_CompanyName,res_GroupId,res_GroupName,res_UserName,res_SessionId, nil];
                    if(!user_q)
                    {
                        [db rollback];
                    }
                    else
                        [db commit];
                }
                else
                {
                    [db beginTransaction];
                    user_q = [db executeUpdate:@"insert into users (company_id, user_id, company_name, group_id, group_name, full_name, guid) values (?,?,?,?,?,?,?)",res_CompanyId,res_UserId,res_CompanyName,res_GroupId,res_GroupName,res_UserName,res_SessionId];
                    if(!user_q)
                    {
                        [db rollback];
                        loginOk = NO;
                        [myDatabase alertMessageWithMessage:@"Login failed. try again."];
                    }

                    else
                        [db commit];
                    
                    //insert/update client user_guid
                    [db beginTransaction];
                    client_q = [db executeUpdate:@"update client set user_guid = ?",res_SessionId];
                    
                    if(!client_q)
                    {
                        loginOk = NO;
                        [myDatabase alertMessageWithMessage:@"Login failed. try again."];
                        [db rollback];
                    }
                    
                    else
                        [db commit];
                    

                }
                
                if(loginOk)
                {
                    [self performSegueWithIdentifier:@"push_main_view" sender:self];
                }
                else
                    DDLogVerbose(@"%@ [%@-%@]",[db lastErrorMessage],THIS_FILE,THIS_METHOD);
            }
            else
            {
                [myDatabase alertMessageWithMessage:@"Invalid login. Please try again."];
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            DDLogVerbose(@"%@ [%@-%@]",error,THIS_FILE,THIS_METHOD);
            
        }];
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DDLogVerbose(@"login segue %@",segue.identifier);
    if([segue.identifier isEqualToString:@"push_main_view"])
    {
        [[self navigationController] setNavigationBarHidden:YES];
        [segue destinationViewController];
    }
    
}


@end
