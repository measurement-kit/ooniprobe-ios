#import "TestRunningViewController.h"
#import "Suite.h"
#import "ProxySettings.h"
#import "RunningTest.h"

@interface TestRunningViewController ()
@end

@implementation TestRunningViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.progressBar.layer.cornerRadius = 7.5;
    self.progressBar.layer.masksToBounds = YES;
    self.proxyView.layer.cornerRadius = 10;
    self.proxyView.layer.masksToBounds = YES;
    [self.progressBar setTrackTintColor:[[UIColor colorNamed:@"color_white"] colorWithAlphaComponent:0.2f]];
    [self.runningTestsLabel setText:NSLocalizedString(@"Dashboard.Running.Running", nil)];
    [self.etaLabel setText:NSLocalizedString(@"Dashboard.Running.EstimatedTimeLeft", nil)];
    [self.interruptButton setTitle:NSLocalizedString(@"Notification.StopTest", nil) forState:UIControlStateNormal];
    [self.proxyLabel setText:NSLocalizedString(@"Dashboard.Running.ProxyInUse", nil)];
    if ([[[[ProxySettings alloc] init] getProxyString] isEqualToString:@""])
        [self.proxyView setHidden:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(testStarted:) name:@"testStarted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress:) name:@"updateProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRuntime) name:@"updateRuntime" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkTestEndedUI) name:@"networkTestEndedUI" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLog:) name:@"updateLog" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showError) name:@"showError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptTestUI) name:@"interruptTestUI" object:nil];

    //Keep screen on
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    if ([RunningTest currentTest].isTestRunning)
        [self testStart];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self addAnimation];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

-(void)testStart{
    if (self.animation)
        [self.animation removeFromSuperview];
    [self.logLabel setText:@""];
    [self.progressBar setProgress:0 animated:YES];
    [self.view setBackgroundColor:[TestUtility getBackgroundColorForTest:[RunningTest currentTest].testSuite.name]];
    [self.timeLabel setText:NSLocalizedString(@"Dashboard.Running.CalculatingETA", nil)];
    if ([RunningTest currentTest].testRunning.isPreparing)
        [self.testNameLabel setText:NSLocalizedString(@"Dashboard.Running.PreparingTest", nil)];
    else
        [self.testNameLabel setText:[LocalizationUtility getNameForTest:[RunningTest currentTest].testRunning.name]];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isViewLoaded && self.view.window) {
            [self addAnimation];
        }
    });
    [self setRuntime];
}

-(void)setRuntime{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.totalRuntime = [[RunningTest currentTest].testSuite getRuntime];
        //We don't want to show -1 seconds before downloading the URL list
        if (self.totalRuntime <= [MAX_RUNTIME_DISABLED intValue])
            return;
        NSString *time = NSLocalizedFormatString(@"Dashboard.Running.Seconds", [NSString stringWithFormat:@"%d", self.totalRuntime]);
        [self.timeLabel setText:time];
    });
}

-(void)addAnimation{
    if ([RunningTest currentTest].testSuite == nil)
        return;
    self.animation = [LOTAnimationView animationNamed:[RunningTest currentTest].testSuite.name];
    self.animation.contentMode = UIViewContentModeScaleAspectFit;
    CGRect c = self.animationView.bounds;
    self.animation.frame = CGRectMake(0, 0, c.size.width, c.size.height);
    [self.animationView setNeedsLayout];
    [self.animationView setClipsToBounds:YES];
    [self.animationView addSubview:self.animation];
    [self.animation setLoopAnimation:YES];
    [self.animation play];
}

-(void)updateLog:(NSNotification *)notification{
    NSDictionary *userInfo = notification.userInfo;
    NSString *log = [userInfo objectForKey:@"log"];
    if (![RunningTest currentTest].testSuite.interrupted)
        [self.logLabel setText:log];
}

-(void)testStarted:(NSNotification *)notification{
    NSDictionary *userInfo = notification.userInfo;
    NSString *name = [userInfo objectForKey:@"name"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.testNameLabel setText:[LocalizationUtility getNameForTest:name]];
    });
}

-(void)updateProgress:(NSNotification *)notification{
    /*
     Format string with minute and seconds
     https://stackoverflow.com/questions/27519533/how-to-format-date-in-to-string-like-as-one-days-ago-minutes-ago-in-ios
     https://stackoverflow.com/questions/2927028/how-do-i-get-hour-and-minutes-from-nsdate
     */
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *prog = [userInfo objectForKey:@"prog"];
    //TODO-2.1 this doesn't take in consideration different test runtimes, only the total
    //But still fixes https://github.com/ooni/probe/issues/805
    float totalTests = [RunningTest currentTest].testSuite.totalTests;
    int index = [RunningTest currentTest].testSuite.measurementIdx;
    float prevProgress = index/totalTests;
    float progress = ([prog floatValue]/totalTests)+prevProgress;
    long eta = self.totalRuntime;
    if (progress > 0) {
        eta = lroundf(self.totalRuntime - progress * self.totalRuntime);
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressBar setProgress:progress animated:YES];
        NSString *time = NSLocalizedFormatString(@"Dashboard.Running.Seconds", [NSString stringWithFormat:@"%ld", eta]);
        [self.timeLabel setText:time];

    });
    [self.animation playWithCompletion:^(BOOL animationFinished) {}];

}

-(void)networkTestEndedUI{
    if ([[RunningTest currentTest].testSuites count] == 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_presenting){
                [self.presentingViewController.presentingViewController dismissViewControllerAnimated:TRUE completion:^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"goToResults" object:nil];
                }];
            }
            else {
                [self dismissViewControllerAnimated:TRUE completion:^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"goToResults" object:nil];
                }];
            }
        });
    }
}

-(void)showError{
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"Modal.OK", nil)
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   [self dismissViewControllerAnimated:YES completion:nil];
                               }];
    [MessageUtility alertWithTitle:NSLocalizedString(@"Modal.Error", nil)
                           message:NSLocalizedString(@"Modal.Error.CantDownloadURLs", nil)
                          okButton:okButton
                      cancelButton:nil
                            inView:self];
}

-(IBAction)cancelTest:(id)sender{
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"Modal.OK", nil)
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"interruptTest" object:nil];
    }];
    [MessageUtility alertWithTitle:NSLocalizedString(@"Modal.InterruptTest.Title", nil)
                           message:NSLocalizedString(@"Modal.InterruptTest.Paragraph", nil)
                          okButton:okButton
                            inView:self];
}

- (void)interruptTestUI {
    [self.runningTestsLabel setText:NSLocalizedString(@"Dashboard.Running.Stopping.Title", nil)];
    [self.logLabel setText:NSLocalizedString(@"Dashboard.Running.Stopping.Notice", nil)];
}

-(IBAction)minimize:(id)sender{
    if (_presenting){
        [self.presentingViewController.presentingViewController dismissViewControllerAnimated:TRUE completion:nil];
    }
    else {
        [self dismissViewControllerAnimated:TRUE completion:nil];
    }
}

@end
