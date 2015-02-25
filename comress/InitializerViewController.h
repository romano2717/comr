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
#import "PostImage.h"
#import "Comment_noti.h"
#import "ImageOptions.h"
#import "UIImageView+WebCache.h"

@interface InitializerViewController : UIViewController
{
    Database *myDatabase;
    AFManager *myAfManager;
    FMDatabaseQueue *databaseQueue;
    FMDatabase *db;
    ImageOptions *imgOpts;
    
    Blocks *blocks;
    Post *posts;
    Comment *comments;
    PostImage *postImage;
    Comment_noti *comment_noti;
    
}
@property (nonatomic, weak) IBOutlet UILabel *processLabel;

@end
