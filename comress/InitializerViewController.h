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
#import "Blocks.h"
#import "Post.h"
#import "Comment.h"

@interface InitializerViewController : UIViewController
{
    Database *myDatabase;
    AFManager *myAfManager;
    FMDatabaseQueue *databaseQueue;
    FMDatabase *db;
    
    Blocks *blocks;
    Post *posts;
    Comment *comments;
    
}
@property (nonatomic, weak) IBOutlet UILabel *processLabel;

@end
