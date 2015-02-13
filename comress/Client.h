//
//  Client.h
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface Client : NSObject
{
    Database *myDatabase;
    FMDatabase *db;
}

@property (nonatomic, strong) NSString *activation_code;
@property (nonatomic, strong) NSString *api_url;
@property (nonatomic, strong) NSString *user_guid;

@end
