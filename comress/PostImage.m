//
//  PostImage.m
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "PostImage.h"

@implementation PostImage

@synthesize
client_post_image_id,
post_image_id,
client_post_id,
post_id,
client_comment_id,
comment_id,
image_path,
status,
downloaded,
uploaded,
image_type,
last_request_date
;

-(id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
        db = [myDatabase prepareDatabaseFor:self];
        
        last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from post_image_last_request_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
    }
    return self;
}

- (long long)savePostImageWithDictionary:(NSDictionary *)dict
{
    BOOL postImageSaved;
    long long postClientImageId = 0;
    
    client_post_image_id    = [NSNumber numberWithInt:[[dict valueForKey:@"client_post_image_id"] intValue]] ;
    post_image_id           = [NSNumber numberWithInt:[[dict valueForKey:@"post_image_id"] intValue]];
    client_post_id          = [NSNumber numberWithInt:[[dict valueForKey:@"client_post_id"] intValue]];
    post_id                 = [NSNumber numberWithInt:[[dict valueForKey:@"post_id"] intValue]];
    client_comment_id       = [NSNumber numberWithInt:[[dict valueForKey:@"client_comment_id"] intValue]];
    comment_id              = [NSNumber numberWithInt:[[dict valueForKey:@"comment_id"] intValue]];
    image_path              = [dict valueForKey:@"image_path"];
    status                  = [dict valueForKey:@"status"];
    downloaded              = [dict valueForKey:@"downloaded"];
    uploaded                = [dict valueForKey:@"uploaded"];
    image_type              = [NSNumber numberWithInt:[[dict valueForKey:@"image_type"] intValue]];
    
    [db beginTransaction];
    
    postImageSaved = [db executeUpdate:@"insert into post_image (client_post_id,image_path,status,downloaded,uploaded,image_type) values (?,?,?,?,?,?)",client_post_id,image_path,status,downloaded,uploaded,image_type];
    
    if(!postImageSaved)
    {
        [db rollback];
        DDLogVerbose(@"insert failed: %@ [%@-%@]",[db lastErrorMessage],THIS_FILE,THIS_METHOD);
    }
    
    else
    {
        [db commit];
        
        postClientImageId = [db lastInsertRowId];
    }
    
    return postClientImageId;
}

- (void)close
{
    [db close];
}

- (NSDictionary *)imagesTosend
{

    NSNumber *zero = [NSNumber numberWithInt:0];
    NSMutableArray *imagesArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *imagesDict = [[NSMutableDictionary alloc] init];
    
    FMResultSet *rs = [db executeQuery:@"select * from post_image where post_image_id is null or post_image_id = ?",zero];
    users = [[Users alloc] init];
    
    while ([rs next]) {
        NSNumber *ImageType = [NSNumber numberWithInt:[rs intForColumn:@"image_type"]];
        NSNumber *CilentPostImageId = [NSNumber numberWithInt:[rs intForColumn:@"client_post_image_id"]];
        NSNumber *PostId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
        NSNumber *CommentId = [NSNumber numberWithInt:[rs intForColumn:@"comment_id"]];
        NSString *CreatedBy = users.user_id;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:[rs stringForColumn:@"image_path"]];
        
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        NSData *imageBase64 = [imageData base64EncodedDataWithOptions:NSDataBase64Encoding64CharacterLineLength];
        NSString *imageString = [NSString stringWithUTF8String:[imageBase64 bytes]];
        
        if(imageString == nil)
            return nil;
        
        if([ImageType intValue] == 1)//post image
        {
            CommentId = [NSNumber numberWithInt:0];
        }
        else if([ImageType intValue] == 2)
        {
            PostId = [NSNumber numberWithInt:0];
        }
        
        
        NSDictionary *dict = @{@"CilentPostImageId":CilentPostImageId,@"PostId":PostId,@"CommentId":CommentId,@"CreatedBy":CreatedBy,@"ImageType":ImageType,@"Image":imageString};
        
        [imagesArray addObject:dict];
    }
    
    if(imagesArray.count == 0)
        return nil;
    
    [imagesDict setObject:imagesArray forKey:@"postImageList"];
    
    return imagesDict;
}


@end
