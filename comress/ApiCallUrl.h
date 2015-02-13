//
//  ApiCallUrl.h
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#ifndef comress_ApiCallUrl_h
#define comress_ApiCallUrl_h

static NSString * AFkey_allowInvalidCertificates = @"allowInvalidCertificates";


static NSString *api_activationUrl = @"http://fmit.com.sg/comressmainservice/AddressManager.svc/json/GetUrlAddress/?group=";

static NSString *api_login = @"User.svc/ComressLogin";

static NSString *api_logout = @"User.svc/Logout?sessionId=";

static NSString *api_post_send = @"Messaging/Post.svc/UploadPost";

static NSString *api_comment_send = @"Messaging/Comment.svc/UploadComment";

static NSString *api_send_images = @"Messaging/PostImage.svc/UploadImageWithBase64";

static NSString *api_download_blocks = @"Job/Block.svc/GetBlocks";
#endif



