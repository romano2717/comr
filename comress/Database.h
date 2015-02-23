//
//  Database.h
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"
#import "AppWideImports.h"
#import <UIKit/UIKit.h>

@interface Database : NSObject
{

}

@property (nonatomic) int initializingComplete;

+ (id)sharedMyDbManager;

- (FMDatabase *) prepareDatabaseFor:(id) obj;
- (void) copyDbToDocumentsDir;
- (BOOL) migrateDatabase;
- (void) alertMessageWithMessage:(NSString *)message;
- (NSString *)dbPath;
- (NSDate *)createNSDateWithWcfDateString:(NSString *)dateString;
@end
