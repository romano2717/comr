//
//  Post.h
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface Post : NSObject
{
    Database *myDatabase;
    FMDatabaseQueue *databaseQueue;
}

@property (nonatomic) int client_post_id;
@property (nonatomic) int post_id;
@property (nonatomic, strong) NSString *post_topic;
@property (nonatomic, strong) NSString *post_by;
@property (nonatomic, strong) NSDate *post_date;
@property (nonatomic, strong) NSString *post_type;
@property (nonatomic, strong) NSString *severity;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *level;
@property (nonatomic, strong) NSNumber *block_id;
@property (nonatomic, strong) NSString *postal_code;

- (long long)savePostWithDictionary:(NSDictionary *)dict;

- (NSArray *)fetchIssuesWithParams:(NSDictionary *)params forPostId:(NSNumber *)postId filterByBlock:(BOOL)filter;

- (void)close;

- (NSArray *)postsToSend;

- (BOOL)updatePostStatusForClientPostId:(NSNumber *)clientPostId withStatus:(NSNumber *)theStatus;

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString;
@end
