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
@property (nonatomic, strong) NSDictionary *imagesDict;

- (void)checkBlockCount;

- (void)checkPostCount;

- (void)checkCommentCount;

-(void)checkPostImagesCount;

-(void)checkCommentNotiCount;

- (void)startDownloadCommentNotiForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi;

- (void)startDownloadPostImagesForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi;

- (void)SavePostImagesToDb;

- (void)startDownloadCommentsForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi;

- (void)startDownloadPostForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi;

- (void)startDownloadBlocksForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi;
@end
