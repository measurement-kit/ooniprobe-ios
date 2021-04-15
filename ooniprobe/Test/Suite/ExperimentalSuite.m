#import "ExperimentalSuite.h"

@implementation ExperimentalSuite

-(id) init {
    self = [super init];
    if (self) {
        self.dataUsage = @"< 1 MB";
        self.name = @"experimental";
    }
    return self;
}

- (NSArray*)getTestList {
    if ([self.testList count] == 0){
        [self.testList addObject:[[Experimental alloc] initTest:@"dnscheck"]];
        [self.testList addObject:[[Experimental alloc] initTest:@"stunreachability"]];
    }
    return super.getTestList;
}

@end
