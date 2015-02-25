//
//  IssuesViewController.m
//  comress
//
//  Created by Diffy Romano on 3/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "IssuesViewController.h"

@interface IssuesViewController ()


@property (nonatomic, strong) NSArray *postsArray;
@property (nonatomic, strong) NSArray *sectionHeaders;

@end


@implementation IssuesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    comment = [[Comment alloc] init];
    user = [[Users alloc] init];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    
    [self.issuesTable addSubview:refreshControl];


    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoOpenChatViewForPost:) name:@"autoOpenChatViewForPost" object:nil];
}

- (void)autoOpenChatViewForPost:(NSNotification *)notif
{
    NSNumber *clientPostId = [NSNumber numberWithLongLong:[[[notif userInfo] valueForKey:@"lastClientPostId"] longLongValue]];
    
    [self performSegueWithIdentifier:@"push_chat_issues" sender:clientPostId];
}

- (IBAction)segmentControlChange:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    self.segment = segment;
    
    [self fetchPosts];
}


- (void)refresh:(id)sender
{
    [self fetchPosts];
    
    [(UIRefreshControl *)sender endRefreshing];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tabBarController.tabBar.hidden = NO;
    self.navigationController.navigationBar.hidden = YES;
    self.hidesBottomBarWhenPushed = NO;
    
    [self fetchPosts];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)didDismissJSQMessageComposerViewController:(IssuesChatViewController *)vc
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"push_chat_issues"])
    {
        self.tabBarController.tabBar.hidden = YES;
        self.hidesBottomBarWhenPushed = YES;
        self.navigationController.navigationBar.hidden = NO;
        
        NSNumber *postId;
        
        if([sender isKindOfClass:[NSIndexPath class]])
        {
            NSIndexPath *indexPath = (NSIndexPath *)sender;
            
            NSDictionary *dict;
            
            if (self.segment.selectedSegmentIndex == 0)
            {
                dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
            }

            else
            {
                dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            }
            
            postId = [NSNumber numberWithInt:[[[dict allKeys] objectAtIndex:0] intValue]];
        }
        else
            postId = sender;
        
        
        BOOL isFiltered = NO;
        
        if(self.segment.selectedSegmentIndex == 0)
            isFiltered = YES;
        
        IssuesChatViewController *issuesVc = [segue destinationViewController];
        issuesVc.postId = [postId intValue];
        issuesVc.isFiltered = isFiltered;
        issuesVc.delegateModal = self;
    }
}

#pragma mark - fetch posts
- (void)fetchPosts
{
    post = nil;
    
    self.postsArray = nil;
    
    post = [[Post alloc] init];
    
    NSDictionary *params = @{@"order":@"order by post_date desc"};
    
    if(self.segment.selectedSegmentIndex == 0)
        self.postsArray = [post fetchIssuesWithParams:params forPostId:nil filterByBlock:YES];
    else
    {
        self.postsArray = [post fetchIssuesWithParams:params forPostId:nil filterByBlock:NO];
        
        NSMutableArray *sectionHeaders = [[NSMutableArray alloc] init];
        
        //reconstruct array to create headers
        for (int i = 0; i < self.postsArray.count; i++) {
            NSDictionary *top = (NSDictionary *)[self.postsArray objectAtIndex:i];
            NSString *topKey = [[top allKeys] objectAtIndex:0];
            
            NSString *post_by = [[[top objectForKey:topKey] objectForKey:@"post"] valueForKey:@"post_by"];
            
            [sectionHeaders addObject:post_by];
        }
        
        //remove dupes of sections
        NSArray *cleanSectionHeadersArray = [[NSOrderedSet orderedSetWithArray:sectionHeaders] array];
        self.sectionHeaders = cleanSectionHeadersArray;
        
        NSMutableArray *groupedPost = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < cleanSectionHeadersArray.count; i++) {
            
            NSString *section = [cleanSectionHeadersArray objectAtIndex:i];
            
            NSMutableArray *row = [[NSMutableArray alloc] init];
            
            for (int j = 0; j < self.postsArray.count; j++) {

                NSDictionary *top = (NSDictionary *)[self.postsArray objectAtIndex:j];
                NSString *topKey = [[top allKeys] objectAtIndex:0];
                NSString *post_by = [[[top objectForKey:topKey] objectForKey:@"post"] valueForKey:@"post_by"];
                
                if([post_by isEqualToString:section])
                {
                    [row addObject:top];
                }
            }
            

            [groupedPost addObject:row];
        }
        
        self.postsArray = groupedPost;
    }
    
    
    [self.issuesTable reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    
    long count;
    
    if(self.segment.selectedSegmentIndex == 0)
        count = 1;
    else
        count = self.sectionHeaders.count;
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    long count;
    
    if(self.segment.selectedSegmentIndex == 0)
        count = self.postsArray.count;
    else
        count = [[self.postsArray objectAtIndex:section] count];

    return count;
}


 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

     IssuesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
     
     NSDictionary *dict;
     
     if(self.segment.selectedSegmentIndex == 0)
         dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
     else
         dict = (NSDictionary *)[[self.postsArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
     
     [cell initCellWithResultSet:dict];
     
     return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(self.segment.selectedSegmentIndex == 1)
        return [self.sectionHeaders objectAtIndex:section];
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"push_chat_issues" sender:indexPath];
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewRowAction *close = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Close" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        
        NSDictionary *dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
        [self setPostStatusAtIndexPath:indexPath withStatus:[NSNumber numberWithInt:4] withPostDict:dict];
        [self fetchPosts];
    }];
    close.backgroundColor = [UIColor darkGrayColor];
    
    UITableViewRowAction *completed = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Completed" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        
        NSDictionary *dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
        
        [self setPostStatusAtIndexPath:indexPath withStatus:[NSNumber numberWithInt:3] withPostDict:dict];
        [self fetchPosts];
    }];
    completed.backgroundColor = [UIColor greenColor];
    
    UITableViewRowAction *start = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Start" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        
        NSDictionary *dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
        
        [self setPostStatusAtIndexPath:indexPath withStatus:[NSNumber numberWithInt:1] withPostDict:dict];
        [self fetchPosts];
    }];
    start.backgroundColor = [UIColor orangeColor];
    
    UITableViewRowAction *stop = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Stop" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        
        NSDictionary *dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
        
        [self setPostStatusAtIndexPath:indexPath withStatus:[NSNumber numberWithInt:2] withPostDict:dict];
        [self fetchPosts];
    }];
    stop.backgroundColor = [UIColor redColor];
    

    return  @[stop, start, completed, close];
}

- (void)setPostStatusAtIndexPath:(NSIndexPath *)indexPath withStatus:(NSNumber *)clickedStatus withPostDict:(NSDictionary *)dict
{
    dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
    NSNumber *clickedPostId = [NSNumber numberWithInt:[[[dict allKeys] objectAtIndex:0] intValue]];

    //update status of this post
    [post updatePostStatusForClientPostId:clickedPostId withStatus:clickedStatus];
    
    NSString *statusString;
    
    switch ([clickedStatus intValue]) {
        case 1:
            statusString = @"Issue set status Start";
            break;
            
        case 2:
            statusString = @"Issue set status Stop";
            break;
            
        case 3:
            statusString = @"Issue set status Completed";
            break;
            
        case 4:
            statusString = @"Issue set status Close";
            break;
            
        default:
            statusString = @"Issue set status Pending";
            break;
    }
    
    
    //create a comment about this post update
    NSDate *date = [NSDate date];
    
    NSDictionary *dictCommentStatus = @{@"client_post_id":clickedPostId, @"text":statusString,@"senderId":user.user_id,@"date":date,@"messageType":@"text",@"comment_type":[NSNumber numberWithInt:2]};
    
    [comment saveCommentWithDict:dictCommentStatus];
}

 // Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

}


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


@end
