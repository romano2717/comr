//
//  AFManager.m
//  comress
//
//  Created by Diffy Romano on 2/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "AFManager.h"

@implementation AFManager
@synthesize api_url;

+(id)sharedMyAfManager {
    static AFManager *sharedMyAfManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyAfManager = [[self alloc] init];
    });
    return sharedMyAfManager;
}

-(id)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (AFHTTPRequestOperationManager *)createManagerWithParams:(NSDictionary *)params
{
    //if(api_url == nil)
        api_url = @"http://comresstest.selfip.com/ComressMWCF/";
    
    //if(client == nil)
        client = [[Client alloc] init];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager.requestSerializer setValue:client.user_guid forHTTPHeaderField:@"ComSessionId"];
    
    DDLogVerbose(@"session: %@",client.user_guid);
    
    //read params
    BOOL allowInvalidCertificates = [[params valueForKey:AFkey_allowInvalidCertificates] boolValue];
    
    if(allowInvalidCertificates == YES)
    {
        AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        policy.allowInvalidCertificates = YES;
        manager.securityPolicy = policy;
    }
    
    return manager;
}

@end
