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

    //check for a valid activation code
    NSString *activationCode = nil;
    
    FMResultSet *rs = [db executeQuery:@"select activation_code from client"];
    while([rs next])
    {
        activationCode = [rs stringForColumn:@"activation_code"];
    }
    
    if(activationCode == nil || activationCode.length == 0)
    {
        needToActivate = YES;
        return;
    }
    
    //check for valid login
    FMResultSet *rsClient = [db executeQuery:@"select c.user_guid, u.* from client c, users u where c.user_guid = u.guid"];
    
    if(![rsClient next])
    {
        needToLogin = YES;
        return;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(needToActivate)
        [self performSegueWithIdentifier:@"modal_activation" sender:self];
    if(needToLogin)
        [self performSegueWithIdentifier:@"modal_login" sender:self];
    else if(!needToActivate && !needToLogin) //init
    {
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
