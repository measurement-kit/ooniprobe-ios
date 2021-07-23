#import <UIKit/UIKit.h>
#import "ConfigureButton.h"
#import "RunButton.h"
#import "TestRunningViewController.h"
#import "Result.h"
#import "SettingsTableViewController.h"
#import "ReachabilityManager.h"
#import "RHMarkdownLabel.h"
#import "Suite.h"

@interface TestOverviewViewController : UIViewController {
    UIColor *defaultColor;
}

@property (nonatomic, strong) AbstractSuite *testSuite;

@property (strong, nonatomic) IBOutlet UIImageView *testImage;
@property (strong, nonatomic) IBOutlet UILabel *testNameLabel;
@property (strong, nonatomic) IBOutlet ConfigureButton *websitesButton;
@property (strong, nonatomic) IBOutlet RunButton *runButton;
@property (strong, nonatomic) IBOutlet UILabel *estimatedLabel;
@property (strong, nonatomic) IBOutlet UILabel *estimatedDetailLabel;
@property (strong, nonatomic) IBOutlet UILabel *lastrunLabel;
@property (strong, nonatomic) IBOutlet UILabel *lastrunDetailLabel;
@property (strong, nonatomic) IBOutlet RHMarkdownLabel *testDescriptionLabel;
@property (strong, nonatomic) IBOutlet UIView *backgroundView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableFooterConstraint;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@end
