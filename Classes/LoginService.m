//
//  LoginService.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 18/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Globals.h"
#import "LoginService.h"

@implementation LoginService

@synthesize user, passwd;

- (id)init {
	if (self = [super init]) {
		doneNotification = LoginDoneNotification;	
		host = DEFAULT_HOST_ADDRESS;
	}
	return self;
}

- (void)dealloc {
	NSLog(@"LoginService::dealloc");
	[super dealloc];
}

- (void)execute
{
    // Construct the request.
    NSString *path = @"/api/login";
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
				  user, @"username",
				  passwd, @"password",
				  kClientVersion, kClientVersionKey,
				  nil];
	
    [self queueRequest:path withParameters: parameters];
}

- (void)loadData:(NSDictionary *)json
{			
	NSString *token = [json objectForKey:@"token"];
	NSString *email = [json objectForKey:@"email"];

	TTLOG(@"Logged in user: %@ (%@)", email, token);

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:token forKey:@"UD_TOKEN"];
	[defaults setObject:email forKey:@"UD_EMAIL"];
	[defaults synchronize];
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInt:0], @"status", token, @"UD_TOKEN", email, @"UD_EMAIL", nil];
	[self forwardResult: dict];	
	[self release];
}

@end
