//
//  LoginUserController.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 18/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LoginUserController.h"
#import "ParabayAppDelegate.h"
#import "Reachability.h"

static NSString* kLoginRequirements = @"You should login if you wish to receive push notifications or sync your Microsoft Outlook data.";


@implementation LoginUserController

@synthesize userName, password, button;

- (id)init
{
    if ((self = [super init])) {
				
		self.tableViewStyle = UITableViewStyleGrouped;
		self.autoresizesForKeyboard = YES;
		self.variableHeightRows = YES;
		
		userName = [[[UITextField alloc] init] autorelease];
		userName.placeholder = NSLocalizedString( @"email", @"email placeholder");
		userName.autocorrectionType = UITextAutocorrectionTypeNo;
		userName.font = TTSTYLEVAR(font);
		userName.keyboardType = UIKeyboardTypeEmailAddress;
		userName.returnKeyType = UIReturnKeyNext;
		userName.clearButtonMode = UITextFieldViewModeWhileEditing;
		userName.autocapitalizationType = UITextAutocapitalizationTypeNone;
		userName.delegate = self;
		userName.tag = 1;
		
		password = [[[UITextField alloc] init] autorelease];
		password.placeholder = NSLocalizedString(@"password", @"password placeholder");
		password.secureTextEntry = TRUE;
		password.font = TTSTYLEVAR(font);
		password.delegate = self;
		password.clearButtonMode = UITextFieldViewModeWhileEditing;
		password.returnKeyType = UIReturnKeyGo;
		password.tag = 2;
				
		button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[button setTitle: NSLocalizedString(@"Login", @"Login") forState:UIControlStateNormal];
		[button addTarget:self action:@selector(processAction)
			forControlEvents:UIControlEventTouchUpInside];
		
		[self createControls];
				
    }
	
    return self;
}

- (void)registerUser {
	
	TTOpenURL(@"tt://register");
}

- (void)createControls {

	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
											   initWithTitle:NSLocalizedString(@"Register", @"Register button") style:UIBarButtonItemStyleBordered
											   target:self action:@selector(registerUser)] autorelease];
		
	self.dataSource = [TTSectionedDataSource dataSourceWithObjects:
					   NSLocalizedString(@"Sign in to Parabay", @"Login screen banner"),
					   [TTTableControlItem itemWithCaption: NSLocalizedString(@"Email:", @"Email label") control:userName],
					   [TTTableControlItem itemWithCaption: NSLocalizedString(@"Password:", @"Password label") control:password],
					   [TTTableControlItem itemWithCaption: nil control:button],
					   [TTTableGrayTextItem itemWithText:[@""
														  stringByAppendingString:kLoginRequirements]],
					   nil];
	
	[userName becomeFirstResponder];	
	
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginNotificationReceived:) name:LoginDoneNotification object:nil];	
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

- (void)loginNotificationReceived:(NSNotification *)aNotification {
		
	NSString *token = [[aNotification userInfo] valueForKey:@"UD_TOKEN"];

	[[Globals sharedInstance] hideSpinner: self.view];
	
	if (token) {
		[self.navigationController popViewControllerAnimated:YES];
	}
	else {
		[[Globals sharedInstance] displayError:NSLocalizedString(@"Failed to login", @"Error message after login")];
	}
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
		
	[textField resignFirstResponder];
	
    if (textField == self.userName) {		
        [password becomeFirstResponder];
	}
	else if (textField == self.password) {
		[self processAction];
	}	

    return YES;
}

- (void)processAction {
	
	if ([[Reachability sharedReachability] internetConnectionStatus] != NotReachable) {
		
		if ([userName.text length] > 0 || [password.text length] > 0) {
			
			[[Globals sharedInstance] showSpinner: self.view];
				
			LoginService *login = [[LoginService alloc]init];

			login.user = userName.text;
			login.passwd = password.text;
			
			[login execute];		
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
