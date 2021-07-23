#import <UIKit/UIKit.h>
#import "SettingsTableViewController.h"
#import "TestRunningViewController.h"
#import "RunButton.h"
#import "ConfigureButton.h"
#import "TestOverviewViewController.h"
#import "ReachabilityManager.h"

@interface DashboardTableViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
}
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *runButton;
@property (nonatomic, strong) NSMutableArray *items;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableFooterConstraint;

@end
