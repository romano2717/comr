//
//  NewIssueViewController.m
//  comress
//
//  Created by Diffy Romano on 3/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "NewIssueViewController.h"

@interface NewIssueViewController ()
{
    BOOL lookingForPostalCodes;
}

@property (nonatomic, strong) NSMutableArray *photoArray;
@property (nonatomic, strong) NSMutableArray *photoArrayFull;
@property (nonatomic, strong) NSArray *severtiyArray;
@property (nonatomic, strong) NSMutableArray *postalCodeResultsArray;
@property (nonatomic, strong) NSMutableArray *addressResultsArray;
@property (nonatomic, strong) NSMutableArray *placeMarksArray;

@end

@implementation NewIssueViewController

@synthesize scrollView,imagePicker;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.photoArray = [[NSMutableArray alloc] init];
    self.photoArrayFull = [[NSMutableArray alloc] init];
    self.severtiyArray = [NSArray arrayWithObjects:@"Routine",@"Severe", nil];
    self.postalCodeResultsArray = [[NSMutableArray alloc] init];
    self.addressResultsArray = [[NSMutableArray alloc] init];
    self.placeMarksArray = [[NSMutableArray alloc] init];
    
    //watch when keyboard is up/down
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    //keyboard can be dimiss by scrollview event
    scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    //set the severity by default to Routine
    self.severityTextField.text = [self.severtiyArray objectAtIndex:0];
    
    //add border to the textview
    [[self.descriptionTextView layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [[self.descriptionTextView layer] setBorderWidth:1];
    [[self.descriptionTextView layer] setCornerRadius:15];
    
    //init location manager
    locationManager = [[CLLocationManager alloc] init];
    locationManager.distanceFilter = 100;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.delegate = self;
    
    //iOS 8
    if([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        [locationManager requestAlwaysAuthorization];
    
    if([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
        [locationManager requestWhenInUseAuthorization];
    
}

- (void)keyboardWillChange:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect rect = [keyboardFrameBegin CGRectValue];
    
    //adjust scrollview contentsize so the keyboard will be just below the add photos button
    CGPoint addPhotosButtonPoint = CGPointMake(0, self.addPhotosButton.frame.origin.y);
    
    float buttonHeight = CGRectGetHeight(self.addPhotosButton.frame);
    float buttonYPos = addPhotosButtonPoint.y;
    
    float newScrollViewContentHeight = buttonYPos + buttonHeight;
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), newScrollViewContentHeight + rect.size.height);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //pre-increase the contentsize of the scrollview to fit screen
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), self.scrollView.contentSize.height + 50);
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"push_view_image"])
    {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        NSInteger index = indexPath.row;
        
        ImagePreviewViewController *imagPrev = [segue destinationViewController];
        
        imagPrev.image = (UIImage *)[self.photoArrayFull objectAtIndex:index];;

    }
}



#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photoArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.selected = YES;
    [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    
    // Configure the cell
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    
    imageView.image = (UIImage *)[self.photoArray objectAtIndex:indexPath.row];
    
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

# pragma mark uiactionsheet
- (IBAction)addPhotoActionSheet:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Add Photos" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera",@"Photo Library", nil];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self openMediaByType:1];
            break;
            
        case 1:
            [self openMediaByType:2];
            break;
    }
    
    [self.view endEditing:YES];
}

#pragma mark image picker
- (void)openMediaByType:(int)type
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    if (type == 1)
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    else
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    picker.delegate = self;
    
    self.imagePicker = picker;
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *img = [info objectForKey:UIImagePickerControllerEditedImage];
    
    if(img == nil)
        img = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    imgOpts = [ImageOptions new];
    
    UIImage *thumbImage = [imgOpts resizeImageAsThumbnailForImage:img];
    
    [self.photoArray addObject:thumbImage];
    [self.photoArrayFull addObject:img];
    
    [self.collectionView reloadData];
}

#pragma mark scrollview delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
}

#pragma mark textfield delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if(textField.tag == 1)//severity
    {
        [ActionSheetStringPicker showPickerWithTitle:@"Severity" rows:self.severtiyArray initialSelection:0 doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
            
            textField.text = [self.severtiyArray objectAtIndex:selectedIndex];
            
        } cancelBlock:^(ActionSheetStringPicker *picker) {
            
        } origin:textField];
        
        lookingForPostalCodes = NO;
        
        [self hideKeyboard:self];
    }
}

- (IBAction)hideKeyboard:(id)sender
{
    [self.view endEditing:YES];
}

- (IBAction)hidePickerView:(id)sender
{

}

#pragma mark uipickerview datasource and delegate
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if(lookingForPostalCodes == NO)
        return self.severtiyArray.count;
    else
        return self.postalCodeResultsArray.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if(lookingForPostalCodes == NO)
        return [self.severtiyArray objectAtIndex:row];
    else
        return [self.addressResultsArray objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if(lookingForPostalCodes == NO)
    {
        self.severityTextField.text = [self.severtiyArray objectAtIndex:row];
    }
    else
    {
        self.postalCodeTextField.text = [self.postalCodeResultsArray objectAtIndex:row];
    }
}

#pragma mark postal codes near you
- (IBAction)postalCodesNearYou:(id)sender
{
    [self.view endEditing:YES];
    
    lookingForPostalCodes = YES;
    
    [locationManager startUpdatingLocation];
    
    [self performSelector:@selector(stopUpdatingLocation) withObject:nil afterDelay:5.0];
}

#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = (CLLocation *)[locations lastObject];
    
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    
    [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if(!error)
        {
            [self storeFoundPlaceMarks:placemarks];
        }
    }];
}

- (void)stopUpdatingLocation
{
    DDLogVerbose(@"found address %@",self.addressResultsArray);
    [locationManager stopUpdatingLocation];
    
    [ActionSheetStringPicker showPickerWithTitle:@"Found Postal Codes" rows:self.addressResultsArray initialSelection:0 doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        
        if(self.addressResultsArray.count > 0)
        {
            self.addressTextField.text = [self.addressResultsArray objectAtIndex:selectedIndex];
            self.postalCodeTextField.text = [self.postalCodeResultsArray objectAtIndex:selectedIndex];
        }
        
        [locationManager stopUpdatingLocation];
        
    } cancelBlock:^(ActionSheetStringPicker *picker) {
        
        
    } origin:self.postalCodesNearYouButton];
}

- (void)storeFoundPlaceMarks:(NSArray *)array
{
    for (int i = 0; i < array.count; i ++) {
        if([self.placeMarksArray containsObject:[array objectAtIndex:i]] == NO)
        {
            [self.placeMarksArray addObject:[array objectAtIndex:i]];
        }
    }
    
    for (int i = 0; i < self.placeMarksArray.count; i++) {
        
        CLPlacemark *pm = (CLPlacemark *)[self.placeMarksArray objectAtIndex:i];
        
        if([self.postalCodeResultsArray containsObject:pm.postalCode] == NO)
        {
            NSDictionary *address = pm.addressDictionary;

            
            if(pm.postalCode.length == 6)
            {
                NSString *postalCode = pm.postalCode;
                NSString *foundAddress = [address valueForKey:@"Name"];
                
                if([self.postalCodeResultsArray containsObject:postalCode] == NO)
                {
                    if(self.postalCodeResultsArray.count > 0)
                    {
                        [self.postalCodeResultsArray insertObject:postalCode atIndex:0];
                        [self.addressResultsArray insertObject:[NSString stringWithFormat:@"%@ - %@",postalCode,foundAddress] atIndex:0];
                    }
                    
                    else
                    {
                        [self.postalCodeResultsArray addObject:postalCode];
                        [self.addressResultsArray addObject:[NSString stringWithFormat:@"%@ - %@",postalCode,foundAddress]];
                    }
                }
            }
        }
    }
}

#pragma mark Save new issue to local db
- (IBAction)postNewIssue:(id)sender
{
    user = [[Users alloc] init];
    post = [[Post alloc] init];
    postImage = [[PostImage alloc] init];
    
    NSString *postal_code = [self.postalCodeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *location = [self.addressTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *level = [self.levelTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *post_topic = [self.descriptionTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *severity = [self.severityTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([severity isEqualToString:@"Routine"])
        severity = @"2";
    else
        severity = @"1";
    
    NSString *post_type = @"1";
    NSString *post_by = user.user_id;
    NSDate *post_date = [NSDate date];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:post_topic,@"post_topic",post_by,@"post_by",post_date,@"post_date",post_type,@"post_type",severity,@"severity",@"0",@"status",location,@"address",level,@"level",postal_code,@"postal_code", nil];
    
    long long lastClientPostId =  [post savePostWithDictionary:dict];
    [post close];

    if(lastClientPostId > 0)
    {
        //save image to app documents dir
        for (int i = 0; i < self.photoArrayFull.count; i++) {
            UIImage *image = [self.photoArrayFull objectAtIndex:i];
            
            NSData *jpegImageData = UIImageJPEGRepresentation(image, 0);
            
            //save the image to app documents dir
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsPath = [paths objectAtIndex:0];
            NSString *imageFileName = [NSString stringWithFormat:@"%@.jpg",[[NSUUID UUID] UUIDString]];
            
            NSString *filePath = [documentsPath stringByAppendingPathComponent:imageFileName]; //Add the file name
            [jpegImageData writeToFile:filePath atomically:YES];
            
            //resize the saved image
            [imgOpts resizeImageAtPath:filePath];
            
            //save the image info to local db
            NSNumber *lastClientPostIdID = [NSNumber numberWithLongLong:lastClientPostId];
            
            NSDictionary *postImageDict = [NSDictionary dictionaryWithObjectsAndKeys:lastClientPostIdID,@"client_post_id",imageFileName,@"image_path",@"new",@"status",@"yes",@"downloaded",@"no",@"uploaded",[NSNumber numberWithInt:1],@"image_type", nil];
            
            long long lastPostImageId = [postImage savePostImageWithDictionary:postImageDict];
            
            if(lastPostImageId > 0)
                DDLogVerbose(@"post successful!");
        }
        
        [postImage close];
    }
}

@end
