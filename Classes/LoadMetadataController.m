//
//  LoadMetadataController.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-10-31.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LoadMetadataController.h"
#import "MetadataDatabase.h"
#import "Reachability.h"

@implementation LoadMetadataController

- (id)init {
	if (self = [super init]) {
		self.title = @"Please wait";
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:LoginDoneNotification object:nil];
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIView

- (void)loadView {
	UIScrollView* scrollView = [[[UIScrollView alloc] initWithFrame:TTNavigationFrame()] autorelease];
	scrollView.backgroundColor = [UIColor whiteColor];
	self.view = scrollView;
	
	label = [[[TTActivityLabel alloc] initWithStyle:TTActivityLabelStyleWhiteBox] autorelease];
	UIView* lastView = [self.view.subviews lastObject];
	label.text = @"Updating application data...";
	label.progress = 0.1;
	[label sizeToFit];
	label.frame = CGRectMake(0, lastView.bottom+150, self.view.width, label.height);
	[self.view addSubview:label];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginNotificationReceived:) name:LoginDoneNotification object:nil];	
	
}

- (void)viewDidAppear:(BOOL)animated {
	
	NetworkStatus status = [[Reachability sharedReachability] internetConnectionStatus];
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* token = [defaults objectForKey:@"UD_TOKEN"];
	
	if (NotReachable != status) {
		if (!token) {
			
			TTOpenURL(@"tt://login");
		}
		else {
			[[MetadataDatabase sharedInstance] refreshMetadataFromServer:self];
		}
	}
}

- (void)loginNotificationReceived:(NSNotification *)aNotification {
	
	NSString *token = [[aNotification userInfo] valueForKey:@"UD_TOKEN"];
	
	if (token) {
		[[MetadataDatabase sharedInstance] refreshMetadataFromServer:self];
	}
}

- (void)progressPending: (NSUInteger) pending withTotal: (NSUInteger) total {
	
	label.progress = 1 - ((float)pending/(float)total);
	if (0 == pending) {
		//[self.navigationController popViewControllerAnimated:YES];
		TTOpenURL(@"tt://home/menu/root");
	}
}

@end
