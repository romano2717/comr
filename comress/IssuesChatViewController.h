//
//  IssuesChatViewController.h
//  comress
//
//  Created by Diffy Romano on 10/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSQMessagesViewController.h"
#import "JSQMessage.h"
#import "MessageData.h"
#import "Users.h"
#import "Comment.h"
#import "Post.h"
#import "NSDate+HumanizedTime.h"
#import "ImageOptions.h"
#import "ImagePreviewViewController.h"

@class IssuesChatViewController;

@class IssuesChatViewController;

@protocol IssuesChatViewControllerDelegate <NSObject>

- (void)didDismissJSQMessageComposerViewController:(IssuesChatViewController *)vc;

@end

@interface IssuesChatViewController : JSQMessagesViewController<UIActionSheetDelegate,CLLocationManagerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    Users *user;
    Comment *comment;
    Post *post;
    ImageOptions *imgOpts;
}

@property (nonatomic, weak) id<IssuesChatViewControllerDelegate> delegateModal;
@property (nonatomic, strong) MessageData *messageData;
@property (nonatomic) int postId;
@property (nonatomic,strong) NSDictionary *postDict;
@property (nonatomic, strong) UIImagePickerController *imagePicker;

@end
