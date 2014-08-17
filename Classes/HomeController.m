//
//  HomeController.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 19/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "HomeController.h"
#import "MetadataService.h"
#import "Globals.h"
#import "ParabayAppDelegate.h"
#import "Airship.h"

UIImage *createImageWithText(CGSize imageSize, NSString *text);

@implementation HomeController

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    float fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

- (UIImage *)makeRoundCornerImage : (UIImage*) img : (int) cornerWidth : (int) cornerHeight
{
	UIImage * newImage = nil;
	
	if( nil != img)
	{
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		int w = img.size.width;
		int h = img.size.height;
		
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
		
		CGContextBeginPath(context);
		CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
		addRoundedRectToPath(context, rect, cornerWidth, cornerHeight);
		CGContextClosePath(context);
		CGContextClip(context);
		
		CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage);
		
		CGImageRef imageMasked = CGBitmapContextCreateImage(context);
		CGContextRelease(context);
		CGColorSpaceRelease(colorSpace);
		[img release];
		
		
		newImage = [[UIImage imageWithCGImage:imageMasked] retain];
		CGImageRelease(imageMasked);
		
		[pool release];
	}
	
    return newImage;
}

// Returns an image of the given size containing the given string
UIImage *createImageWithText(CGSize imageSize, NSString *text) {
	
	// Create a bitmap graphics context of the given size
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, 8, imageSize.width*4, colorSpace, kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(colorSpace);
	if (context== NULL) {
		return nil;
	}
	
	// Custom CGContext coordinate system is flipped with respect to UIView, so transform, then push
	CGContextTranslateCTM(context, 0, imageSize.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	UIGraphicsPushContext(context);
	
	CGRect square = CGRectMake (0, 0, imageSize.width, imageSize.height);
	[[UIColor blackColor] set];
	UIRectFill (square);
	
	// Inset the text rect then draw the text
	CGRect textRect = CGRectMake(4, 2, imageSize.width - 8, imageSize.height - 8);
	UIFont *font = [UIFont boldSystemFontOfSize:20];
	[[UIColor whiteColor] set];
	[text drawInRect:textRect withFont:font lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
	
	// Create and return the UIImage object
	CGImageRef cgImage = CGBitmapContextCreateImage(context); 
	UIImage *uiImage = [[UIImage alloc] initWithCGImage:cgImage];
	UIGraphicsPopContext();
	CGContextRelease(context);
	CGImageRelease(cgImage);
	return uiImage;
}

- (id)initWithName:(NSString*)name query:(NSDictionary*)query {
	
	if (self = [super init]) {
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.title = @"Home";
		
		// Create the tableview.
		self.tableViewStyle = UITableViewStyleGrouped;
		self.autoresizesForKeyboard = YES;
		self.variableHeightRows = YES;
		
		UIImage* image = [UIImage imageNamed:@"pages.png"];
		self.tabBarItem = [[[UITabBarItem alloc] initWithTitle:self.title image:image tag:0] autorelease];
		
		self.navigationItem.hidesBackButton = YES;
		BOOL storeDisabled = [defaults boolForKey:@"disable_store_preference"]; 
		if (!storeDisabled && ([[[UIDevice currentDevice] model] compare:@"iPhone Simulator"] != NSOrderedSame)) {
			
			self.navigationItem.leftBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"Shop" style:UIBarButtonItemStyleBordered 
														  target:self action:@selector(settings)];
		}
		
		NSString* token = [defaults objectForKey:@"UD_TOKEN"];
		if (token) {
			self.navigationItem.rightBarButtonItem =
			[[[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Logout", @"Logout") style:UIBarButtonItemStyleBordered
											 target:[Globals sharedInstance]
											 action:@selector(logout)] autorelease];	
		}
		
		MetadataService *metadataService = [MetadataService sharedInstance];
		NSArray *rootViews = [metadataService getRootViews];
		
		if (rootViews) {
			NSMutableArray *rows = [[NSMutableArray alloc] init];
			for(NSDictionary *result in rootViews) {   
				
				NSString *viewMap = [result objectForKey:@"title"];
				NSString *name = [result objectForKey:@"name"];
				
				if (NSOrderedSame != [name compare:@"Inbox_Emails"]) {
				
					if ([viewMap length] == 0) {
						viewMap = [result objectForKey:@"description"];
					}
					
					UIImage *img = createImageWithText(CGSizeMake(32, 32), [viewMap substringToIndex:1]);
					UIImage *defaultImage = [self makeRoundCornerImage:img :6 :6];
					TTTableImageItem *row = [TTTableImageItem itemWithText:viewMap imageURL:@"" defaultImage: defaultImage  URL:[NSString stringWithFormat: @"tt://home/list/%@", name]];
					[rows addObject:row];
				}
			}
			
			UIImage *img = createImageWithText(CGSizeMake(32, 32), @"B");
			UIImage *defaultImage = [self makeRoundCornerImage:img :6 :6];
			TTTableImageItem *row = [TTTableImageItem itemWithText:@"About" imageURL:@"" defaultImage: defaultImage  URL:@"tt://home/about"];
			[rows addObject:row];
			
			/*
			[rows addObject: [TTTableLink itemWithText:@"Maps" URL:@"tt://map"] ];
			[rows addObject: [TTTableLink itemWithText:@"Images" URL:@"tt://image"] ];
			[rows addObject: [TTTableLink itemWithText:@"About" URL:@"tt://home/about"] ];
			*/
			
			self.dataSource = [TTListDataSource dataSourceWithItems:rows];
			[rows release];
		}
		
	}
	return self;
}

- (void)logout {
	
	[[Globals sharedInstance] logout];
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];	
	[defaults removeObjectForKey:@"UD_TOKEN"];
}

- (void)settings {
	
	[[Airship shared] displayStoreFront];
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

- (void)didReceiveMemoryWarning   
{  
	NSLog(@"HomeController:didReceiveMemoryWarning");
    //[super didReceiveMemoryWarning];  
} 

- (void)viewDidLoad {
	[super viewDidLoad];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL noads = [defaults boolForKey:@"noads_paid"];

	if (!noads) {
		ParabayAppDelegate *delegate = (ParabayAppDelegate *)[[UIApplication sharedApplication] delegate];
		[delegate startAdQueryFromHostView: self.view];
	}
	else {
		NSLog(@"Skipping ads for paid user");
	}

}

- (void)viewDidUnload {
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL noads = [defaults boolForKey:@"noads_paid"];
	
	if (!noads) {
		ParabayAppDelegate *delegate = (ParabayAppDelegate *)[[UIApplication sharedApplication] delegate];
		[delegate stopAdQueryFromHostView: self.view];	
	}	

	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	[super viewDidUnload];	
}

@end
