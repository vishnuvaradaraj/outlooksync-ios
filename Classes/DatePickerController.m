
#import "DatePickerController.h"
#import "EntityEditorController.h"

@implementation DatePickerController

@synthesize pickerView,textField, dateFormatter, propertyName, parentEditor, datePickerMode, timeFormatter;


- (id)initWithProperty:(NSString*)name query:(NSDictionary*)query {
	
	if (self = [super init]) {
		self.propertyName = name;
		self.datePickerMode = UIDatePickerModeDate;
		
		self.dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[self.dateFormatter setDateStyle:kCFDateFormatterLongStyle];
		[self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		
		timeFormatter = [[NSDateFormatter alloc] init];
		[timeFormatter setDateFormat:@"HH:mm"];

		if ([ [[TTNavigator navigator] topViewController] isKindOfClass:[EntityEditorController class]]) {
			self.parentEditor = (EntityEditorController *) [[TTNavigator navigator] topViewController];
		}
		
		NSString *name = [query objectForKey:@"display"];
		if (NSOrderedSame == [name compare:@"time"]) {
			self.datePickerMode = UIDatePickerModeTime;
			[self.dateFormatter setDateStyle:NSDateFormatterNoStyle];
			[self.dateFormatter setTimeStyle:kCFDateFormatterMediumStyle];			
		}
		
		self.tableViewStyle = UITableViewStyleGrouped;
		self.autoresizesForKeyboard = YES;
		self.variableHeightRows = YES;
						
		self.pickerView = [[UIDatePicker alloc] initWithFrame:CGRectMake(0.0, 44.0, 320.0, 216.0)];
		self.pickerView.datePickerMode = self.datePickerMode;
		[self.pickerView addTarget:self action:@selector(dateAction:) forControlEvents:UIControlEventValueChanged];
		
		self.navigationItem.rightBarButtonItem = 
			[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)] autorelease];	
		self.navigationItem.leftBarButtonItem = 
			[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
													   target:self action:@selector(cancelAction)] autorelease];
		
		[self.navigationItem setHidesBackButton:YES];
		
		self.textField = [[[UITextField alloc] init] autorelease];
		self.textField.userInteractionEnabled = NO;
		self.textField.text = @"";
		
		self.dataSource = [TTSectionedDataSource dataSourceWithObjects:
						   self.propertyName,
						   self.textField,
						   nil];
		
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];
		
	if (self.parentEditor) {
		NSDate *value = [self.parentEditor.item valueForKey: self.propertyName];
		value = [self normalizeDate:value];
		
		self.pickerView.date = [value copy];
		self.textField.text = [self.dateFormatter stringFromDate:value];
	}	
	
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
	[UIView setAnimationDuration:0.1];
	
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
	[UIView setAnimationDuration:0.1];
	
	// we need to perform some post operations after the animation is complete
	[UIView setAnimationDelegate:self];
	
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

- (NSDate *) normalizeDate: (NSDate *)date {
	
	NSDate *value = date;
	if (!value) {
		value = [NSDate date];
	}
	
	if (self.datePickerMode == UIDatePickerModeTime) {
		value = [self dateAsTimeWithoutSeconds:value];
	}
	else {
		value = [self dateAsDateWithoutTime:value];
	}

	
	//NSLog(@"Date=%@", value);
	return value;
}

- (NSDate *)dateAsTimeWithoutSeconds: (NSDate *)date
{	
	NSString *formattedString = [timeFormatter stringFromDate:date];
    NSDate *ret = [timeFormatter dateFromString:formattedString];
	
    return ret;
}

- (NSDate *)dateAsDateWithoutTime: (NSDate *)date
{	
	NSString *formattedString = [dateFormatter stringFromDate:date];
    NSDate *ret = [dateFormatter dateFromString:formattedString];
	
    return ret;
}

- (void)doneAction:(id)sender
{		
	if (self.parentEditor) {
		
		NSDate *value = self.pickerView.date;
		if (self.datePickerMode == UIDatePickerModeTime) {
			value = [self dateAsTimeWithoutSeconds:value];
		}
		
		[self.parentEditor.item setValue:[value retain] forKey:propertyName];
		self.parentEditor.item = self.parentEditor.item;
		[self.parentEditor.tableView reloadData];
	}	
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)dateAction:(id)sender
{
	NSDate *value = [self normalizeDate: self.pickerView.date];	
	self.textField.text = [self.dateFormatter stringFromDate:value];
}

- (void)dealloc
{	
	[pickerView release];
	[dateFormatter release];
	
	[super dealloc];
}

@end

