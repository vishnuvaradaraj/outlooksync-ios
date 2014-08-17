//
//  LogoutService.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 18/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Globals.h"
#import "LogoutService.h"
#import "ParabayAppDelegate.h"

@implementation LogoutService

@synthesize token;

- (id)init {
	if (self = [super init]) {
		doneNotification = LogoutDoneNotification;		
	}
	return self;
}

- (void)dealloc {
	NSLog(@"LogoutService::dealloc");
	[super dealloc];
}

- (void)execute
{	
    // Construct the request.
    NSString *path = @"/api/logout";
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								token, @"token",
								kClientVersion, kClientVersionKey,
								nil];
	
    [self queueRequest:path withParameters: parameters];
}

- (void)loadData:(NSDictionary *)json
{		
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];	
	[defaults removeObjectForKey:@"UD_TOKEN"];
	//[defaults removeObjectForKey:@"UD_EMAIL"];
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInt:0], @"status", nil];
	
	ParabayAppDelegate *appDelegate = (ParabayAppDelegate *) [[UIApplication sharedApplication] delegate];
	[appDelegate clearUserData];
	
	[self forwardResult: dict];
	[self release];
}

@end
