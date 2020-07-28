#import "CountlyUtility.h"
#import "SettingsUtility.h"

@implementation CountlyUtility

+ (void)initCountly {
    CountlyConfig* config = CountlyConfig.new;
    config.appKey = @"146836f41172f9e3287cab6f2cc347de3f5ddf3b";
    config.host = NOTIFICATION_SERVER;
    //Dabug builds
    #ifndef DEBUG
        config.enableDebug = YES;
        config.pushTestMode = CLYPushTestModeDevelopment;
    #endif
    //Only for testflights build
    //config.pushTestMode = CLYPushTestModeTestFlightOrAdHoc;
    config.features = @[CLYPushNotifications, CLYCrashReporting, CLYAutoViewTracking];
    //TODO-COUNTLY
    config.deviceID = @"Lorenzo-iOS";
    config.requiresConsent = YES;
    [Countly.sharedInstance startWithConfig:config];
    [self reloadConsents];
}

+ (void)reloadConsents{
    [Countly.sharedInstance cancelConsentForAllFeatures];

    if ([SettingsUtility isSendCrash])
        [Countly.sharedInstance giveConsentForFeature:CLYConsentCrashReporting];
    
    if ([SettingsUtility isSendAnalytics])
        [Countly.sharedInstance giveConsentForFeatures:@[CLYConsentSessions,
                                                         CLYConsentViewTracking,
                                                         CLYConsentEvents]];

    if ([SettingsUtility isNotification])
        [Countly.sharedInstance giveConsentForFeature:CLYConsentPushNotifications];
}

@end