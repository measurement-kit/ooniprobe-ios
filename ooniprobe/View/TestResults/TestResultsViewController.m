#import "TestResultsViewController.h"
#import "UploadFooterViewController.h"
#import "ThirdPartyServices.h"
#import "ThirdPartyServices.h"
#import "MBProgressHUD.h"
#import "RunningTest.h"

@interface TestResultsViewController ()

@end

@implementation TestResultsViewController
@synthesize results;

- (void)awakeFromNib{
    [super awakeFromNib];
    self.title = NSLocalizedString(@"TestResults.Overview.Title", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadConstraints) name:@"networkTestEndedUI" object:nil];
    [NavigationBarUtility setNavigationBar:self.navigationController.navigationBar];
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.estimatedRowHeight = 80.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self reloadConstraints];
    self.title = @"";
    self.title = NSLocalizedString(@"TestResults.Overview.Title", nil);
}

-(void)reloadConstraints{
    CGFloat tableConstraint = 0;
    CGFloat uploadConstraint = 0;
    if ([RunningTest currentTest].isTestRunning){
        tableConstraint += 64;
        uploadConstraint += 64;
    }
    if (![Result isEveryResultUploaded:results]){
        tableConstraint += 45;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.tableFooterConstraint.constant = tableConstraint;
        self.uploadbarFooterConstraint.constant = uploadConstraint;
        [self.tableView setNeedsUpdateConstraints];
        [self.tableView reloadData];
    });
}

-(void)testFilter:(SRKQuery*)newQuery{
    query = newQuery;
    results = [query fetch];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM";
    for (Result *current in results){
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        NSString *key = [df stringFromDate:current.start_time];
        if (key == nil){
            //reporting error and delete test
            [ThirdPartyServices recordError:@"key_nil"
                                   reason:@"testFilter key is null"
                                 userInfo:[current dictionary]];
            [current deleteObject];
        }
        else {
            if ([dic objectForKey:key])
                arr = [[dic objectForKey:key] mutableCopy];
            [arr addObject:current];
            [dic setObject:arr forKey:key];
        }
    }
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"" ascending:NO selector:@selector(localizedStandardCompare:)];
    keys = [[dic allKeys] sortedArrayUsingDescriptors:@[ descriptor ]];
    resultsDic = dic;
    [self reloadConstraints];
}

#pragma mark - Table view data source

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"ooni_empty_state"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = NSLocalizedString(@"TestResults.Overview.NoTestsHaveBeenRun", nil);
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"FiraSans-Regular" size:16],
                                 NSForegroundColorAttributeName:[UIColor colorNamed:@"color_gray5"]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *month = [keys objectAtIndex:section];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM";
    NSDate *convertedDate = [df dateFromString:month];
    df.dateFormat = @"MMMM yyyy";
    return [[df stringFromDate:convertedDate] uppercaseString];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor colorNamed:@"color_gray9"]];
    [header.textLabel setFont:[UIFont fontWithName:@"FiraSans-Regular" size:14]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [keys count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [(NSArray*)[resultsDic objectForKey:[keys objectAtIndex:section]] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Result *current = [[resultsDic objectForKey:[keys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    TestResultTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[TestResultTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    [cell setResult:current];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Result *current = [[resultsDic objectForKey:[keys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        [current deleteObject];
        [self testFilter:query];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadHeader" object:nil];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView.contentOffset.y<=0) {
        scrollView.contentOffset = CGPointZero;
    }
}

-(IBAction)removeAllTests:(id)sender{
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"Modal.Delete", nil)
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                [self deleteAll];
                               }];
    [MessageUtility alertWithTitle:nil
                           message:NSLocalizedString(@"Modal.DoYouWantToDeleteAllTests", nil)
                          okButton:okButton
                            inView:self];
}

-(void)deleteAll{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [TestUtility cleanUp];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self testFilter:query];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadHeader" object:nil];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    });
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Result *result = [[resultsDic objectForKey:[keys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    if ([result.measurements count] > 0){
        [self performSegueWithIdentifier:@"summary" sender:self];
    }
    else
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Navigation

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"header"]){
        ResultsHeaderViewController *vc = (ResultsHeaderViewController * )segue.destinationViewController;
        [vc setDelegate:self];
    }
    else if ([[segue identifier] isEqualToString:@"summary"]){
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        TestSummaryViewController *vc = (TestSummaryViewController * )segue.destinationViewController;
        Result *current = [[resultsDic objectForKey:[keys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        if (!current.is_viewed){
            [current setIs_viewed:YES];
            [current save];
        }
        [vc setResult:current];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if ([[segue identifier] isEqualToString:@"footer_upload"]){
        UploadFooterViewController *vc = (UploadFooterViewController * )segue.destinationViewController;
        [vc setUpload_all:true];
    }
}

@end
