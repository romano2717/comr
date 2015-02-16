//
//  IssuesViewController.m
//  comress
//
//  Created by Diffy Romano on 3/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "IssuesViewController.h"

@interface IssuesViewController ()


@property (nonatomic, strong)NSArray *postsArray;

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
            NSDictionary *dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
            postId = [NSNumber numberWithInt:[[[dict allKeys] objectAtIndex:0] intValue]];
        }
        else
            postId = sender;
        
        IssuesChatViewController *issuesVc = [segue destinationViewController];
        issuesVc.postId = [postId intValue];
        issuesVc.delegateModal = self;
    }
}

#pragma mark - fetch posts
- (void)fetchPosts
{
    post = [[Post alloc] init];
    
    NSDictionary *params = @{@"order":@"order by post_date desc"};
    self.postsArray = [post fetchIssuesWithParams:params forPostId:nil];
    
    [self.issuesTable reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.postsArray.count;
}


 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

     IssuesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
     NSDictionary *dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];

     [cell initCellWithResultSet:dict];
     
     return cell;
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
        [self setPostStatusAtIndexPath:indexPath withStatus:[NSNumber numberWithInt:4]];
        [self fetchPosts];
    }];
    close.backgroundColor = [UIColor darkGrayColor];
    
    UITableViewRowAction *completed = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Completed" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [self setPostStatusAtIndexPath:indexPath withStatus:[NSNumber numberWithInt:3]];
        [self fetchPosts];
    }];
    completed.backgroundColor = [UIColor greenColor];
    
    UITableViewRowAction *start = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Start" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [self setPostStatusAtIndexPath:indexPath withStatus:[NSNumber numberWithInt:1]];
        [self fetchPosts];
    }];
    start.backgroundColor = [UIColor orangeColor];
    
    UITableViewRowAction *stop = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Stop" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [self setPostStatusAtIndexPath:indexPath withStatus:[NSNumber numberWithInt:2]];
        [self fetchPosts];
    }];
    stop.backgroundColor = [UIColor redColor];
    

    return  @[stop, start, completed, close];
}

- (void)setPostStatusAtIndexPath:(NSIndexPath *)indexPath withStatus:(NSNumber *)clickedStatus
{
    NSDictionary *dict = (NSDictionary *)[self.postsArray objectAtIndex:indexPath.row];
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
