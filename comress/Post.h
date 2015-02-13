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
    FMDatabase *db;
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
@property (nonatomic, strong) NSString *block_id;
@property (nonatomic, strong) NSString *postal_code;

- (long long)savePostWithDictionary:(NSDictionary *)dict;
- (NSArray *)fetchIssuesWithParams:(NSDictionary *)params forPostId:(NSNumber *)postId;
- (void)close;
- (NSArray *)postsToSend;
@end
