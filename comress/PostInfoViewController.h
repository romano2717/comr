//
//  PostInfoViewController.h
//  comress
//
//  Created by Diffy Romano on 14/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "ImagePreviewViewController.h"

@interface PostInfoViewController : UIViewController<UICollectionViewDataSource,UICollectionViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *issueLabel;
@property (nonatomic, weak) IBOutlet UILabel *issueByLabel;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *levelLabel;
@property (nonatomic, weak) IBOutlet UILabel *severityLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UICollectionView *theCollectionView;

@property (nonatomic, strong) NSDictionary *postInfoDict;

@property (nonatomic, strong) NSMutableArray *imagesArray;
@end
