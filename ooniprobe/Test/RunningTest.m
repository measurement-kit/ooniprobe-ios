#import "RunningTest.h"

@implementation RunningTest

static RunningTest *currentTest = nil;

+ (RunningTest *) currentTest
{
    @synchronized(self)
    {
        if (currentTest == nil)
        {
            currentTest = [[RunningTest alloc] init];
            currentTest.isTestRunning = false;
            [[NSNotificationCenter defaultCenter] addObserver:currentTest selector:@selector(networkTestEnded) name:@"networkTestEnded" object:nil];
        }
    }
    return currentTest;
}


-(void)clearSuites {
    @synchronized(self)
    {
        currentTest.testSuites = [[NSMutableArray alloc] init];
    }
}

-(void)setAndRun:(NSMutableArray*)testSuites {
    @synchronized(self)
    {
        currentTest.testSuites = testSuites;
        [currentTest runTest];
    }
}

-(void)runTest{
    if ([currentTest.testSuites count] == 0)
        return;
    currentTest.testSuite = [currentTest.testSuites objectAtIndex:0];
    [currentTest.testSuite runTestSuite];
}

-(void)networkTestEnded{
    [currentTest.testSuites removeObject:currentTest.testSuite];
    if ([currentTest.testSuites count] == 0){
        [currentTest clearSuites];
    }
    else
        [self runTest];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"networkTestEndedUI" object:nil];
}

@end
