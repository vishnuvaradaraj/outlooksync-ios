//
//  LogicTests.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-12-03.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LogicTests.h"
//#import "ParabayAppDelegate.h"

@implementation LogicTests

#if USE_APPLICATION_UNIT_TEST     // all code under test is in the iPhone Application

- (void) setUp {
	STAssertNotNil(@"", @"Could not create test subject.");
}

- (void) tearDown {

}

- (void) testAppDelegate {
    
	//ParabayAppDelegate *delegate = (ParabayAppDelegate *) [[UIApplication sharedApplication] delegate];
    //STAssertNotNil(delegate, @"UIApplication failed to find the AppDelegate");
    
}

- (void) testPass {
	STAssertTrue(TRUE, @"");
}


#endif


@end
