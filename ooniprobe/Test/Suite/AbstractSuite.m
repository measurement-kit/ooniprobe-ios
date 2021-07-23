#import "Suite.h"
#import "RunningTest.h"

@implementation AbstractSuite

-(id) init {
    self = [super init];
    if (self) {
        self.backgroundTask = UIBackgroundTaskInvalid;
        self.testList = [[NSMutableArray alloc] init];
        self.storeDB = YES;
    }
    return self;
}

-(id)initSuite:(NSString*)testSuite{
    if ([testSuite isEqualToString:@"websites"])
        self = [[WebsitesSuite alloc] init];
    else if ([testSuite isEqualToString:@"performance"])
        self = [[PerformanceSuite alloc] init];
    else if ([testSuite isEqualToString:@"middle_boxes"])
        self = [[MiddleBoxesSuite alloc] init];
    else if ([testSuite isEqualToString:@"instant_messaging"])
        self = [[InstantMessagingSuite alloc] init];
    else if ([testSuite isEqualToString:@"circumvention"])
        self = [[CircumventionSuite alloc] init];
    return self;
}

-(void)runTestSuite {
    self.interrupted = false;
    self.totalTests = [[self getTestList] count];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptTest) name:@"interruptTest" object:nil];
    [self newResult];
    dispatch_queue_t serialQueue = dispatch_queue_create("org.openobservatory.queue", DISPATCH_QUEUE_SERIAL);
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }];
    //prepare measurements
    [[RunningTest currentTest] setTestSuite:self];
    [RunningTest currentTest].isTestRunning = true;
    for (AbstractTest *current in [self getTestList]){
        [current setDelegate:self];
        [current setSerialQueue:serialQueue];
        [current setResult:self.result];
    }
    [self runNextMeasurement];
}

-(void)runNextMeasurement{
    if ([self.testList count] > 0){
        AbstractTest *current = [self.testList objectAtIndex:0];
        [RunningTest currentTest].testRunning = current;
        [current runTest];
    }
}

- (void)interruptTest{
    NSLog(@"interruptTest AbstractSuite %@", self.name);
    self.interrupted = true;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"interruptTest" object:nil];
}

-(void)testEnded:(AbstractTest*)test{
    [self.testList removeObject:test];
    [self.result save];
    self.measurementIdx++;
    if (self.interrupted)
        [self.testList removeAllObjects];
    //if last test
    if ([self.testList count] == 0){
        [self.result setIs_done:YES];
        [self.result save];
        UIApplicationState state = [[UIApplication sharedApplication] applicationState];
        if (state == UIApplicationStateBackground || state == UIApplicationStateInactive){
            [self showLocalNotification];
        }
        //Resetting class values
        self.result = nil;
        self.measurementIdx = 0;
        [RunningTest currentTest].isTestRunning = false;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"networkTestEnded" object:nil];
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
    else {
        //Run next test
        [self runNextMeasurement];
    }
}

- (void)showLocalNotification {
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate date];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.alertBody = [NSString stringWithFormat:@"%@ %@", [LocalizationUtility getNameForTest:self.result.test_group_name], NSLocalizedString(@"Notification.FinishedRunning", nil)];
    [localNotification setApplicationIconBadgeNumber:[[UIApplication sharedApplication] applicationIconBadgeNumber] + 1];
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

-(NSArray*)getTestList {
    return self.testList;
}

-(void)newResult {
    if (self.storeDB == false)
        return;
    //For rerun measurement result is set by the view controller
    if (self.result == nil){
        self.result = [Result new];
        [self.result setTest_group_name:self.name];
        //The Result object needs to be saved to have an Id, needed for log
        [self.result save];
    }
}

-(int)getRuntime{
    int runtime = 0;
    for (AbstractTest *current in [self getTestList]){
        runtime+=[current getRuntime];
    }
    return runtime;
}

@end
