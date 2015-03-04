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
    BOOL needToInit;
}
@end

@implementation TabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //check for a valid activation code
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSString *activationCode = nil;
        
        FMResultSet *rs = [db executeQuery:@"select activation_code from client"];
        while([rs next])
        {
            activationCode = [rs stringForColumn:@"activation_code"];
        }
        
        if(activationCode == nil || activationCode.length == 0)
        {
            needToActivate = YES;
        }
        else
        {
            //check for valid login
            FMResultSet *rsClient = [db executeQuery:@"select c.user_guid, u.* from client c, users u where c.user_guid = u.guid"];
            
            if(![rsClient next])
            {
                needToLogin = YES;
            }
            
            else if(!needToActivate && !needToLogin) //init
            {
                if(myDatabase.initializingComplete == 0)
                {
                    needToInit = YES;
                }
            }
        }
    }];
    
    if(needToActivate)
    {
        [self performSegueWithIdentifier:@"modal_activation" sender:self];
    }
    else if (needToLogin)
    {
        [self performSegueWithIdentifier:@"modal_login" sender:self];
    }
    else
    {
        if(myDatabase.initializingComplete == 0)
            [self performSegueWithIdentifier:@"modal_initializer" sender:self];
    }
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
