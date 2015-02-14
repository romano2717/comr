//
//  PostInfoViewController.m
//  comress
//
//  Created by Diffy Romano on 14/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "PostInfoViewController.h"

@interface PostInfoViewController ()

@end

@implementation PostInfoViewController

@synthesize postInfoDict;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.issueLabel.text = [[postInfoDict objectForKey:@"post"] valueForKey:@"post_topic"];
    
    self.issueByLabel.text = [NSString stringWithFormat:@"Issue by: %@",[[postInfoDict objectForKey:@"post"] valueForKey:@"post_by"]];
    
    self.locationLabel.text = [NSString stringWithFormat:@"%@ %@",[[postInfoDict objectForKey:@"post"] valueForKey:@"postal_code"],[[postInfoDict objectForKey:@"post"] valueForKey:@"address"]];

    
    if([[[postInfoDict objectForKey:@"post"] valueForKey:@"severity"] intValue] == 2)
        self.severityLabel.text = @"Routine";
    else
        self.severityLabel.text = @"Severe";

    self.levelLabel.text = [NSString stringWithFormat:@"Level: %@",[[postInfoDict objectForKey:@"post"] valueForKey:@"level"]];
    
    NSArray *imagesDictArr = [postInfoDict objectForKey:@"images"];
    self.imagesArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < imagesDictArr.count; i++) {
        NSDictionary *imagesDict = [imagesDictArr objectAtIndex:i];
        
        NSString *imagePath = [imagesDict valueForKey:@"image_path"];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:imagePath];
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        
        [self.imagesArray addObject:image];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imagesArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.selected = YES;
    [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    
    // Configure the cell
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    
    imageView.image = (UIImage *)[self.imagesArray objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    cell.contentView.backgroundColor = [UIColor blueColor];
    
    [self performSegueWithIdentifier:@"push_view_image" sender:indexPath];
}


@end
