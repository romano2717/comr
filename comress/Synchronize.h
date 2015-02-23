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

@interface Synchronize : NSObject
{
    AFManager *myAfManager;
    Database *myDatabase;
    FMDatabase *db;
    FMDatabaseQueue *databaseQueue;
}

+ (id)sharedManager;

- (void)uploadPost;

- (void)uploadComment;

- (void)uploadImage;

- (void)downloadPost;

- (void)downloadComments;

- (void)downloadPostImages;

- (void)downloadCommentNoti;

- (void)updateReadStatus;
@end
