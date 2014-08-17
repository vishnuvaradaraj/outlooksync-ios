//
//  RegisterService.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 18/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Globals.h"
#import "RegisterService.h"

@implementation RegisterService

- (id)init {
	if (self = [super init]) {
		doneNotification = RegistrationDoneNotification;		
	}
	return self;
}

- (void)execute
{
    // Construct the request.
    NSString *path = @"/api/register_user";
	NSString *userCsv = [NSString stringWithFormat:@"{\"password\":\"%@\",\"name\":\"%@\",\"email\":\"%@\"}", password, user, user];
	
	NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
				  userCsv, @"user",
				  [[Globals sharedInstance] appName], @"app",
				  kClientVersion, kClientVersionKey,
				  nil];
	
    [self queueRequest:path withParameters: parameters];
}

@end
