#import "DashboardTableViewController.h"
#import "DashboardTableViewCell.h"
#import "ThirdPartyServices.h"
#import "Suite.h"
#import "RunningTest.h"

@interface DashboardTableViewController ()

@property (weak, nonatomic) IBOutlet UIView *viewForShadowRunButton;
@property (weak, nonatomic) IBOutlet UILabel *lastrunLabel;

@end

@implementation DashboardTableViewController
@synthesize items;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setShadowRunButton];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadTests) name:@"settingsChanged" object:nil];
    [NavigationBarUtility setNavigationBar:self.navigationController.navigationBar];
    [self loadTests];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadConstraints) name:@"networkTestEndedUI" object:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [self reloadConstraints];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO];
}

-(void)reloadConstraints{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([RunningTest currentTest].isTestRunning){
            self.tableFooterConstraint.constant = 64;
            [self.tableView setNeedsUpdateConstraints];
        }
        else {
            //If this number is > 0 there are still test running
            if ([[RunningTest currentTest].testSuites count] == 0){
                self.tableFooterConstraint.constant = 0;
                [self.tableView setNeedsUpdateConstraints];
            }
        }
        [self.tableView reloadData];
        [self reloadLastMeasurement];
    });
}

-(void)setShadowRunButton{
    self.runButton.layer.cornerRadius = 20;
    self.runButton.layer.masksToBounds = YES;
    [self.runButton setTitle:[NSString stringWithFormat:@"%@", NSLocalizedString(@"Dashboard.Card.Run", nil)] forState:UIControlStateNormal];

    self.viewForShadowRunButton.backgroundColor = [UIColor clearColor];
    
    self.viewForShadowRunButton.layer.shadowRadius  = 5.0f;
    self.viewForShadowRunButton.layer.shadowColor   = [[UIColor colorNamed:@"color_black"] colorWithAlphaComponent:0.8f].CGColor;
    self.viewForShadowRunButton.layer.shadowOffset  = CGSizeMake(0.0f, 2.0f);
    self.viewForShadowRunButton.layer.shadowOpacity = 0.6f;
    self.viewForShadowRunButton.layer.masksToBounds = NO;
}

-(void)loadTests{
    items = [TestUtility getTestObjects];
    [self.tableView reloadData];
}

-(void)reloadLastMeasurement{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *ago;
        SRKResultSet *results = [[[[Result query] limit:1] orderByDescending:@"start_time"] fetch];
        if ([results count] > 0){
            ago = [[[results objectAtIndex:0] start_time] timeAgoSinceNow];
        }
        else
            ago = NSLocalizedString(@"Dashboard.Overview.LastRun.Never", nil);
        [self.lastrunLabel setText:[NSString stringWithFormat:@"%@ %@",
                                          NSLocalizedString(@"Dashboard.Overview.LatestTest", nil),
                                          ago]];
    });
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [items count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DashboardTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    AbstractSuite *test = [items objectAtIndex:indexPath.row];
    if (cell == nil) {
        cell = [[DashboardTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    [cell setTestSuite:test];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

-(IBAction)run:(id)sender{
    if ([TestUtility checkConnectivity:self] &&
        [TestUtility checkTestRunning:self])
    [self performSegueWithIdentifier:@"toTestRun" sender:sender];
}

-(IBAction)runAll{
    if ([TestUtility checkConnectivity:self] &&
        [TestUtility checkTestRunning:self])
        [self performSegueWithIdentifier:@"toTestRunAll" sender:self];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"toTestRun"]){
        UITableViewCell* cell = (UITableViewCell*)[[[sender superview] superview] superview];
        NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
        AbstractSuite *testSuite = [items objectAtIndex:indexPath.row];
        [[RunningTest currentTest] setAndRun:[NSMutableArray arrayWithObject:testSuite]];
    }
    else if ([[segue identifier] isEqualToString:@"toTestRunAll"]){
        [[RunningTest currentTest] setAndRun:[NSMutableArray arrayWithArray:items]];
    }
    else if ([[segue identifier] isEqualToString:@"toTestOverview"]){
        NSIndexPath* indexPath = [self.tableView indexPathForSelectedRow];
        TestOverviewViewController *vc = (TestOverviewViewController * )segue.destinationViewController;
        AbstractSuite *testSuite = [items objectAtIndex:indexPath.row];
        [vc setTestSuite:testSuite];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }    
}


@end
