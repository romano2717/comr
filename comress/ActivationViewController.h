//
//  ActivationViewController.h
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"
#import "AFManager.h"
#import "LoginViewController.h"

@interface ActivationViewController : UIViewController
{
    Database *myDatabase;
    AFManager *myAfManager;
}

@property (nonatomic, weak) IBOutlet UITextField *activationCodeTextField;
@end
