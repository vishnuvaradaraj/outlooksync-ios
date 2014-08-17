//
//  RegisterUserController.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 17/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "RegisterUserController.h"
#import "Reachability.h"
#import "Globals.h"

@implementation RegisterUserController

- (id)init
{
    if ((self = [super init])) {
		[button setTitle: NSLocalizedString(@"Register", @"Register") forState:UIControlStateNormal];
    }
	
    return self;
}

- (void)createControls {
	
	self.dataSource = [TTSectionedDataSource dataSourceWithObjects:
					   NSLocalizedString(@"Register Parabay user", @"User registration page"),
					   [TTTableControlItem itemWithCaption: NSLocalizedString(@"Email:", @"Email label") control:userName],
					   [TTTableControlItem itemWithCaption: NSLocalizedString(@"Password:", @"Password label") control:password],
					   [TTTableControlItem itemWithCaption: nil control:button],
					   nil];
	
	[userName becomeFirstResponder];	
	
}

- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];	
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger theme = [defaults integerForKey:@"theme_preference"];
	
	if (theme == 2) {
		UIApplication* app = [UIApplication sharedApplication];
		[app setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
		
		self.navigationController.navigationBar.tintColor = [UIColor 
															 blackColor]; 			
	}
	
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registerNotificationReceived:) name:RegistrationDoneNotification object:nil];	
}

- (void)registerNotificationReceived:(NSNotification *)aNotification {
	
	NSString *token = [[aNotification userInfo] valueForKey:@"UD_TOKEN"];
	
	[[Globals sharedInstance] hideSpinner: self.view];
	
	if (token) {
		[self.navigationController popViewControllerAnimated:YES];
		[[Globals sharedInstance] displayInfo:NSLocalizedString(@"Registration successful", @"Success message after registration")];
	}
	else {
		NSString *errorMessage = nil;
		
		NSNumber *status = (NSNumber *) [[aNotification userInfo] valueForKey:@"status"];
		if ([status intValue] == 3) {
			errorMessage = NSLocalizedString(@"User already exists", @"Error message after registration");
		}
		else {
			errorMessage = NSLocalizedString(@"Failed to register", @"Error message after registration");
		}
	
		[[Globals sharedInstance] displayError:errorMessage];
	}
}

- (void)processAction {
	
	if ([[Reachability sharedReachability] internetConnectionStatus] != NotReachable) {
		
		if ([userName.text length] > 0 || [password.text length] > 0) {
			
			[[Globals sharedInstance] showSpinner: self.view];
			
			RegisterService *registerService = [[RegisterService alloc]init];
			registerService.user = userName.text;
			registerService.passwd = password.text;
			
			[registerService execute];		
		}
		else {
			[[Globals sharedInstance] displayError:NSLocalizedString(@"Please enter a valid username and password", @"Invalid login error message")];
		}
		
	}
	else {
		[[Globals sharedInstance] displayError:NSLocalizedString(@"Network is not available", @"Network error message")];
	}
	
}

- (void)dealloc {
	
	[super dealloc];
}

@end
