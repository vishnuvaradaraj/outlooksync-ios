//
//  ListPickerController.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 29/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ListPickerController.h"


@implementation ListPickerController

@synthesize pickerView,textField, propertyName, pickerViewArray;

- (CGRect)pickerFrameWithSize:(CGSize)size
{
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	CGRect pickerRect = CGRectMake(	0.0,
								   screenRect.size.height - 84.0 - size.height,
								   size.width,
								   size.height);
	return pickerRect;
}

- (id)initWithProperty:(NSString*)name query:(NSDictionary*)query {
	if (self = [super init]) {
		self.propertyName = name;
		self.tableViewStyle = UITableViewStyleGrouped;
		self.autoresizesForKeyboard = YES;
		self.variableHeightRows = YES;
				
		pickerViewArray = [[NSArray arrayWithObjects:
							@"John Appleseed", @"Chris Armstrong", @"Serena Auroux",
							@"Susan Bean", @"Luis Becerra", @"Kate Bell", @"Alain Briere",
							nil] retain];
		// note we are using CGRectZero for the dimensions of our picker view,
		// this is because picker views have a built in optimum size,
		// you just need to set the correct origin in your view.
		//
		// position the picker at the bottom
		pickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
		CGSize pickerSize = [pickerView sizeThatFits:CGSizeZero];
		pickerView.frame = [self pickerFrameWithSize:pickerSize];
		
		pickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		pickerView.showsSelectionIndicator = YES;	// note this is default to NO
		
		// this view controller is the data source and delegate
		pickerView.delegate = self;
		pickerView.dataSource = self;
		
		self.navigationItem.rightBarButtonItem = 
		[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)] autorelease];	
		self.navigationItem.leftBarButtonItem = 
		[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
													   target:self action:@selector(cancelAction)] autorelease];
		
		[self.navigationItem setHidesBackButton:YES];
		
		self.textField = [[[UITextField alloc] init] autorelease];
		self.textField.text = @"placeholder";
		
		self.dataSource = [TTSectionedDataSource dataSourceWithObjects:
						   self.propertyName,
						   self.textField,
						   nil];
		
	}
	return self;
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


- (void)viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
		
	[self.view.window addSubview: self.pickerView];
	
	// size up the picker view to our screen and compute the start/end frame origin for our slide up animation
	//
	// compute the start frame
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	CGSize pickerSize = [self.pickerView sizeThatFits:CGSizeZero];
	CGRect startRect = CGRectMake(0.0,
								  screenRect.origin.y + screenRect.size.height,
								  pickerSize.width, pickerSize.height);
	self.pickerView.frame = startRect;
	
	// compute the end frame
	CGRect pickerRect = CGRectMake(0.0,
								   screenRect.origin.y + screenRect.size.height - pickerSize.height,
								   pickerSize.width,
								   pickerSize.height);
	// start the slide up animation
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	// we need to perform some post operations after the animation is complete
	[UIView setAnimationDelegate:self];
	
	self.pickerView.frame = pickerRect;
	
	// shrink the table vertical size to make room for the date picker
	CGRect newFrame = self.tableView.frame;
	newFrame.size.height -= self.pickerView.frame.size.height;
	self.tableView.frame = newFrame;
	[UIView commitAnimations];
	
}

- (void)viewWillDisappear:(BOOL)animated {
	
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	CGRect endFrame = self.pickerView.frame;
	endFrame.origin.y = screenRect.origin.y + screenRect.size.height;
	
	// start the slide down animation
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	// we need to perform some post operations after the animation is complete
	[UIView setAnimationDelegate:self];
	//[UIView setAnimationDidStopSelector:@selector(slideDownDidStop)];
	
	self.pickerView.frame = endFrame;
	[UIView commitAnimations];
	
	// grow the table back again in vertical size to make room for the date picker
	CGRect newFrame = self.tableView.frame;
	newFrame.size.height += self.pickerView.frame.size.height;
	self.tableView.frame = newFrame;
		
	[super viewWillDisappear:animated];
	
}

- (void)cancelAction {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)doneAction:(id)sender
{	
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)picker didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	self.textField.text  = [NSString stringWithFormat:@"%@",
					  [pickerViewArray objectAtIndex:[picker selectedRowInComponent:0]]];
}


#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	NSString *returnStr = [pickerViewArray objectAtIndex:row];
	return returnStr;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	return 280.0;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 40.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [pickerViewArray count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

- (void)dealloc
{	
	[pickerView release];	
	[super dealloc];
}

@end
