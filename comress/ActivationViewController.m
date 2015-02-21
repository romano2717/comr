//
//  ActivationViewController.m
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ActivationViewController.h"

@interface ActivationViewController ()

@end

@implementation ActivationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    myAfManager = [AFManager sharedMyAfManager];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doActivate:(id)sender
{
    NSString *activateCode = [self.activationCodeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if(activateCode != nil && activateCode.length > 0)
    {
        AFHTTPRequestOperationManager *manager = [myAfManager createManagerWithParams:@{AFkey_allowInvalidCertificates:@YES}];
        
        [manager GET:[NSString stringWithFormat:@"%@%@",api_activationUrl,activateCode] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            DDLogVerbose(@"%@",responseObject);
            NSDictionary *dict = (NSDictionary *)responseObject;
            
            if([[dict valueForKey:@"isValid"] intValue] == 1)
            {
                myAfManager.api_url = [dict valueForKey:@"api_url"];
                
                FMDatabase *db = [myDatabase prepareDatabaseFor:self];
                
                BOOL q;
                
                FMResultSet *rs = [db executeQuery:@"select activation_code from client"];
                if([rs next])
                {
                    [db beginTransaction];
                    q = [db executeUpdate:@"update client set activation_code = ?, api_url = ?",activateCode,[dict valueForKey:@"url"]];
                    if(!q)
                        [db rollback];
                    else
                        [db commit];
                }
                else
                {
                    [db beginTransaction];
                    q = [db executeUpdate:@"insert into client(activation_code, api_url) values(?,?)",activateCode,[dict valueForKey:@"url"]];
                    if(!q)
                        [db rollback];
                    else
                        [db commit];
                }
                
                if(q)
                {
                    [self performSegueWithIdentifier:@"push_the_login" sender:self];
                }
            }
            else
            {
                [myDatabase alertMessageWithMessage:@"Invalid Activation code. Please try again."];
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription, THIS_FILE,THIS_METHOD);
            
        }];
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DDLogVerbose(@"activation segue %@",segue.identifier);
    if([segue.identifier isEqualToString:@"push_the_login"])
    {
        LoginViewController *login =  [segue destinationViewController];
    }
}


@end
