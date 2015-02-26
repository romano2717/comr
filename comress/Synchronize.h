//
//  Synchronize.h
//  comress
//
//  Created by Diffy Romano on 9/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"
#import "AFManager.h"
#import "Database.h"
#import "Post.h"
#import "Comment.h"
#import "PostImage.h"
#import "Users.h"
#import "Comment_noti.h"
#import "InitializerViewController.h"
#import "ImageOptions.h"

@interface Synchronize : NSObject
{
    AFManager *myAfManager;
    Database *myDatabase;
    FMDatabaseQueue *databaseQueue;
    InitializerViewController *init;
    
    Blocks *blocks;
    Post *post;
    PostImage *postImage;
    Comment *comment;
    
    ImageOptions *imgOpts;
}

@property (nonatomic, strong) NSMutableArray *imagesArray;

+ (id)sharedManager;


//upload

- (void)uploadPost;

- (void)uploadComment;

- (void)uploadImage;

- (void)uploadPostStatusChange;



//download

- (void)startDownloadPostForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate;

- (void)startDownloadPostImagesForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate;

- (void)startDownloadCommentsForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate;
@end
