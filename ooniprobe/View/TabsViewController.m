#import "TabsViewController.h"
#import "MessageUtility.h"
#import "Measurement.h"
#import "SettingsUtility.h"

@interface TabsViewController ()

@end

@implementation TabsViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showToast:) name:@"showToast" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openSettings) name:@"openSettings" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goToResults) name:@"goToResults" object:nil];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (![[NSUserDefaults standardUserDefaults] objectForKey:ONBOARDING_KEY]){
        [self performSegueWithIdentifier:@"showInformedConsent" sender:self];
    }
    
    //Show this only on app open, not every time after reloading the scren
    if (modalShowed) return;
    if ([SettingsUtility getAppOpenCount] != 0 &&
       [SettingsUtility getAppOpenCount] % AUTOTEST_POPUP_COUNT == 0 &&
       ![SettingsUtility isAutomatedTestEnabled] &&
       ![[NSUserDefaults standardUserDefaults] objectForKey:AUTOTEST_POPUP_DISABLE]){
        [MessageUtility autotestAlertinView:self];
        modalShowed = true;
    }
    else if ([SettingsUtility getAppOpenCount] != 0 &&
        [SettingsUtility getAppOpenCount] % NOTIFICATION_POPUP_COUNT == 0 &&
        ![SettingsUtility isNotificationEnabled] &&
        ![[NSUserDefaults standardUserDefaults] objectForKey:NOTIFICATION_POPUP_DISABLE]){
        [MessageUtility notificationAlertinView:self];
        modalShowed = true;
    }
}

-(void)setModalValue:(BOOL)value key:(NSString*)key popupName:(NSString*)popupName{
    [[NSUserDefaults standardUserDefaults] setObject:@"ok" forKey:popupName];
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:key];
}

-(void)showToast:(NSNotification *) notification{
    NSDictionary *userInfo = notification.userInfo;
    NSString *message = [userInfo objectForKey:@"message"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view makeToast:NSLocalizedString(message, nil)];
    });
}

- (void)openSettings{
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *navController = [[self viewControllers] objectAtIndex:2];
        [navController popToRootViewControllerAnimated:NO];
        [self setSelectedIndex:2];
    });
}

-(void)goToResults{
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *navController = [[self viewControllers] objectAtIndex:1];
        [navController popToRootViewControllerAnimated:NO];
        [self setSelectedIndex:1];
    });
}

@end
