//
//  AFManager.h
//  comress
//
//  Created by Diffy Romano on 2/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApiCallUrl.h"
#import "AFHTTPRequestOperationManager.h"
#import "Client.h"

@interface AFManager : NSObject
{
    Client *client;
}

@property (nonatomic, strong) NSString *api_url;

- (AFHTTPRequestOperationManager *)createManagerWithParams:(NSDictionary *)params;
+ (id)sharedMyAfManager;

@end
