//
//  InitializerViewController.h
//  comress
//
//  Created by Diffy Romano on 12/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"
#import "AFManager.h"

@interface InitializerViewController : UIViewController
{
    Database *myDatabase;
    AFManager *myAfManager;
    FMDatabaseQueue *databaseQueue;
    FMDatabase *db;
}
@property (nonatomic, weak) IBOutlet UILabel *processLabel;

@end
