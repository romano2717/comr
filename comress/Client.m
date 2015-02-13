//
//  Client.m
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Client.h"

@implementation Client

@synthesize
activation_code,
api_url,
user_guid;

-(id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
        db = [myDatabase prepareDatabaseFor:self];
        
        FMResultSet *rs = [db executeQuery:@"select * from client"];
        while ([rs next]) {
            activation_code = [rs stringForColumn:@"activation_code"];
            api_url = [rs stringForColumn:@"api_url"];
            user_guid = [rs stringForColumn:@"user_guid"];
        }
    }
    
    return self;
}

@end
