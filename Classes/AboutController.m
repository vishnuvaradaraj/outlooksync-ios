//
//  AboutController.m
//  LoginApp
//
//  Created by Vishnu Varadaraj on 10/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AboutController.h"
#import "Globals.h"
#import "MetadataDatabase.h"
#import "ParabayAppDelegate.h"

static NSString* kAboutUs = @"Founded in 2008, we are innovative providers of online services which are not limited by the browser. \
We are focused on bringing our customers the best user experience on the next-gen smart-phones.";

@implementation AboutController

- (TTStyle*)blueToolbarButton:(UIControlState)state {
	TTShape* shape = [TTRoundedRectangleShape shapeWithRadius:4.5];
	UIColor* tintColor = RGBCOLOR(30, 110, 255);
	return [TTSTYLESHEET toolbarButtonForState:state shape:shape tintColor:tintColor font:nil];
}

- (id)init
{
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"About", @"About page title");
   
		// Create the tableview.
		self.tableViewStyle = UITableViewStyleGrouped;
		self.autoresizesForKeyboard = YES;
		self.variableHeightRows = YES;
		
		
		UIImage* image = [UIImage imageNamed:@"settings.png"];
		self.tabBarItem = [[[UITabBarItem alloc] initWithTitle:self.title image:image tag:0] autorelease];
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];		
		NSString* token = [defaults objectForKey:@"UD_TOKEN"];
		if (token) {
			self.navigationItem.rightBarButtonItem =
			[[[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Logout", @"Logout") style:UIBarButtonItemStyleBordered
											 target:[Globals sharedInstance]
											 action:@selector(logout)] autorelease];	
		}
		
		self.dataSource = [TTListDataSource dataSourceWithObjects:
						   [TTTableImageItem itemWithText: @"Parabay Inc." imageURL:@"bundle://logot57.png"
													  URL:@"http://www.parabay.com"],
						   [TTTableSubtextItem itemWithText: NSLocalizedString(@"About Us", @"About us page")
													caption:kAboutUs],
						   [TTTableGrayTextItem itemWithText:@"(c)2009 Parabay Inc. All rights reserved."],
						   [TTTableTextItem itemWithText: @"Check support messages" 
													  URL:@"http://parabayweb.appspot.com/messages/index.html"],
						   [TTTableTextItem itemWithText:@"Submit Feedback" URL:@"tt://feedback"],
						   nil];	
		
		
		//self.tableView.tableFooterView = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[[TTNavigator navigator].URLMap from:@"tt://feedback"
							toModalViewController:self selector:@selector(displayComposerSheet:)];
		
    }
	
    
    return self;
}

// Displays an email composition interface inside the application. Populates all the Mail fields. 
- (UIViewController*)displayComposerSheet:(NSDictionary*)query  {
	
	if ([MFMailComposeViewController canSendMail]) {
		
		MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
		picker.mailComposeDelegate = self;
		
		[picker setSubject:@"Feedback on iPhone Calendar App"];
		NSArray *toRecipients = [NSArray arrayWithObject:@"feedback@parabay.com"]; 	
		[picker setToRecipients:toRecipients];
		
		ParabayAppDelegate *delegate = (ParabayAppDelegate *)[[UIApplication sharedApplication] delegate];
		NSString *logPath = [ [delegate applicationDocumentsDirectory] stringByAppendingPathComponent: kLogFilePath];
		NSData *data = [NSData dataWithContentsOfMappedFile:logPath];

		[picker addAttachmentData:data mimeType:@"text/plain" fileName:kLogFilePath];	
		return picker;
	}
	
	return nil;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	switch (result)
	{
		case MFMailComposeResultCancelled:
			NSLog(@"Result: sent");
			break;
		default:
			NSLog(@"Result: not sent");
			break;
	}	
	[self dismissModalViewControllerAnimated:YES];
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

- (void)dealloc {
	[[TTNavigator navigator].URLMap removeURL:@"tt://feedback"];
	
    [super dealloc];
}


@end

