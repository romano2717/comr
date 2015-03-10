//
//  IssuesTableViewCell.m
//  comress
//
//  Created by Diffy Romano on 5/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "IssuesTableViewCell.h"

@implementation IssuesTableViewCell

@synthesize mainImageView,statusLabel,statusProgressView,postTitleLabel,addressLabel,lastMessagByLabel,lastMessageLabel,dateLabel,messageCountLabel,pinImageView,readStatusImageView;


- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict
{
    NSDictionary *topDict = (NSDictionary *)[[dict allValues] firstObject];
    NSDictionary *postDict = [topDict valueForKey:@"post"];
    NSArray *postComments = [topDict valueForKey:@"postComments"];
    NSArray *postImages = [topDict valueForKey:@"postImages"];
    
    NSString *postTopic = [postDict valueForKey:@"post_topic"] ? [postDict valueForKey:@"post_topic"] : @"Untitled";
    
    //post date
    double timeStamp = [[postDict valueForKeyPath:@"post_date"] doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    NSString *dateStringForm = [date stringWithHumanizedTimeDifference:0 withFullString:NO];
    
    //post main image
    NSDictionary *imageDict = (NSDictionary *)[postImages firstObject];
    NSString *imagePath = [imageDict valueForKey:@"image_path"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:imagePath];
    NSURL *imageUrl = [NSURL fileURLWithPath:filePath];
    
    //last message & last message by
    //by default, last post is by OP until last commenter
    NSString *lastMsgBy = [postDict valueForKey:@"post_by"];
    NSString *lastMsg = @"";
    
    //read status
    int readStatus = [[topDict valueForKey:@"readStatus"] intValue];
    
    int severity = [[postDict valueForKey:@"severity"] intValue];
    
    NSDictionary *lastCommentDict = [postComments lastObject];

    if (postComments.count > 0) {
        
        lastMsgBy = [lastCommentDict valueForKey:@"comment_by"];
        lastMsg = [lastCommentDict valueForKey:@"comment"];
    }
    
    //status
    int status = [[postDict valueForKey:@"status"] intValue] ? [[postDict valueForKey:@"status"] intValue] : 0;
    CGFloat progress = 0.0; //Pending
    NSString *statusString;
    
    switch (status) {
            
        case 1:
        {
            progress = 0.5;
            statusString = @"In Progress";
            break;
        }

        case 2:
        {
            progress = 0.2;
            statusString = @"Stop";
            break;
        }
            
        case 3:
        {
            progress = 1.0;
            statusString = @"Completed";
            break;
        }
            
        case 4:
        {
            progress = 0;
            statusString = @"Close";
            break;
        }
            
            
        default:
        {
            progress = 0.2;
            statusString = @"Pending";
            break;
        }

    }

    
    //set ui
    
    [mainImageView sd_setImageWithURL:imageUrl placeholderImage:[UIImage imageNamed:@"noImage"] options:SDWebImageProgressiveDownload];
    statusLabel.text = statusString;
    statusProgressView.progress = progress;
    postTitleLabel.text = postTopic;
    addressLabel.text = [postDict valueForKey:@"address"] ? [postDict valueForKey:@"address"] : @"Address:";
    lastMessagByLabel.text = lastMsgBy;
    lastMessageLabel.text = lastMsg;
    dateLabel.text = dateStringForm ? dateStringForm : @"-";
    messageCountLabel.text = @"";
    
    if(severity == 2)//Routine
        pinImageView.hidden = YES;
    
    if(readStatus == 1)
    {
        readStatusImageView.hidden = YES;
    }
    
}


@end
