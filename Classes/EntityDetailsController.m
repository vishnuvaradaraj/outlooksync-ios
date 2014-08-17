//
//  EntityDetailsController.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 19/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EntityDetailsController.h"
#import "DatePickerController.h"
#import "ParabayAppDelegate.h"
#import "MetadataService.h"
#import "PageData.h"
#import "JSON.h"

@implementation EntityDetailsController

@synthesize item, pageName, pageData, entityDescription, managedObjectContext, propertyEditors, isReadOnly;


- (void) initMetadata {
	
	self.pageData = [[MetadataService sharedInstance] getPageData:nil forEditorPage:pageName];
			
	NSArray *groups = [self.pageData.editorLayout objectForKey:@"groups"];		
	self.propertyEditors = [[NSMutableDictionary alloc] init];
	
	self.isReadOnly = NO;
	NSNumber *readOnly = [self.pageData.listLayout objectForKey:@"readonly"];
	if (readOnly && [readOnly boolValue])  {
		self.isReadOnly = YES;
	}	
	
	NSMutableArray *sections = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *items = [[[NSMutableArray alloc] init] autorelease];
	
	for(NSDictionary *group in groups) {

		NSString *groupName = [group objectForKey:@"name"];
		NSArray *fields = [group objectForKey:@"fields"];
		
		NSMutableArray *sectionItems = [[[NSMutableArray alloc] init] autorelease];
		[sections addObject:groupName];
		[items addObject: sectionItems];
		
		for(NSDictionary *field in fields) {
			
			NSDictionary *params = [field objectForKey:@"params"];
			NSString *propertyName = [params objectForKey:@"data"];
			NSString *type = [field objectForKey:@"type"];
					
			//NSLog(@"Property: %@ (%@)", propertyName, type);
			TTTableControlItem *tableItem = nil;
			
			if (NSOrderedSame == [type compare:@"text"]) {
				
				tableItem = [TTTableSubtextItem itemWithText:propertyName
													 caption:@" "];
			} else if (NSOrderedSame == [type compare:@"image"]) {
				
				NSString *url = [NSString stringWithFormat:@"tt://home/view/image/%@", propertyName];
				tableItem = [TTTableImageItem itemWithText:propertyName imageURL:@""
											  defaultImage:nil imageStyle:TTSTYLE(rounded)
													   URL:url];
				
			} else {
				UITextField* textField = [[[UITextField alloc] init] autorelease];
				textField.placeholder = propertyName;
				textField.font = TTSTYLEVAR(font);
				textField.enabled = NO;
				
				tableItem = [TTTableControlItem itemWithCaption:propertyName
																				control:textField];
			}
						
			tableItem.userInfo = [field retain];
			
			[sectionItems addObject:tableItem];
			[self.propertyEditors setObject:tableItem forKey: propertyName];
		}
	}
	
	self.dataSource = [TTSectionedDataSource dataSourceWithItems:items sections: sections];	
	[self.propertyEditors release];	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataSavedNotificationReceived:) name:DataSavedNotification object:nil];	
}

- (void)dataSavedNotificationReceived:(NSNotification *)aNotification {
	
	NSString *key = [[aNotification userInfo] valueForKey:@"id"];
	NSString *page = [[aNotification userInfo] valueForKey:@"pageName"];
	
	if (key && page) {
		if ((NSOrderedSame == [page compare:self.pageName]) && 
			(NSOrderedSame == [key compare:[item valueForKey:@"name"] ])) {
			
			self.item = item;
			[self.tableView reloadData];
		}
	}
}

- (id)initWithViewMap:(NSString*)name query:(NSDictionary*)query {
	
	if (self = [super init]) {
		
		self.tableViewStyle = UITableViewStyleGrouped;
		self.autoresizesForKeyboard = YES;
		self.variableHeightRows = YES;
		
		pageName = [name copy];
		NSArray *nameComponents = [name componentsSeparatedByString:@"_"];
		self.title = [nameComponents objectAtIndex:1];
		
		[self initMetadata];
		
		if (!self.isReadOnly) {
			self.navigationItem.rightBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit:)];
		}
		
		NSManagedObject *data = [query objectForKey:@"data"];
		if (!data) {
			NSString *name = [query objectForKey:@"id"];
			data = [self itemWithKey:name];
		}

		self.item = data;
	}
	
	return self;
}		

- (NSManagedObjectContext *)managedObjectContext {
	
    if (managedObjectContext == nil) {
		ParabayAppDelegate *delegate = (ParabayAppDelegate *) [[UIApplication sharedApplication] delegate];
        managedObjectContext = [delegate managedObjectContext];
    }
    return managedObjectContext;
}

- (NSEntityDescription *)entityDescription {
	
    if (entityDescription == nil) {		
		entityDescription = [NSEntityDescription entityForName:pageData.defaultEntityName inManagedObjectContext: self.managedObjectContext];		
    }
    return entityDescription;
}

- (NSManagedObject *)itemWithKey: (NSString *)name {
	
	NSManagedObject *ret = nil;

	if (name) {
				
		NSFetchRequest *req = [[NSFetchRequest alloc] init];
		[req setEntity:self.entityDescription];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:
								  @"name = %@", name];
		[req setPredicate:predicate];
		
		NSError *error = nil;
		NSArray *array = [self.managedObjectContext executeFetchRequest:req error:&error];
		if ((error != nil) || (array == nil)) {
			NSLog(@"Error while fetching\n%@",
				  ([error localizedDescription] != nil)
				  ? [error localizedDescription] : @"Unknown Error");
		}
		
		if ([array count] > 0) {
			ret = [array objectAtIndex:0];
		}else {
			ret = [[NSManagedObject alloc] initWithEntity:self.entityDescription insertIntoManagedObjectContext:self.managedObjectContext];
		}
		
		[req release];
		
	}
	
	return ret;
}

- (void)setItem:(NSManagedObject*)aValue {
	
	TT_RELEASE_SAFELY(item);
	item = [aValue retain];
	
	for(NSString *key in self.propertyEditors) {
		@try {
			
			TTTableControlItem *tableItem = [self.propertyEditors objectForKey:key];
			NSDictionary *field = [tableItem userInfo];
			NSString *type = [field objectForKey:@"type"];
			
			if (NSOrderedSame == [type compare:@"text"]) {
				
				TTTableSubtextItem* subTextItem = (TTTableSubtextItem *)tableItem;
				subTextItem.caption = @" ";
				
				if (item && [item valueForKey:key])
					subTextItem.caption = [[item valueForKey:key] description];
			} else if (NSOrderedSame == [type compare:@"image"]) {
				
				TTTableImageItem *imageItem = (TTTableImageItem *) tableItem;
				imageItem.defaultImage = [[Globals sharedInstance] thumbnailForProperty:key inItem: item];
				
			} else {
				
				UITextField* textField = (UITextField *)tableItem.control;
				textField.text = @" ";
				
				if (item) {
					
					NSString *value = [[item valueForKey:key] description];
					if (NSOrderedSame == [type compare:@"date"]) {
						
						value = [[Globals sharedInstance].dateFormatter stringFromDate:[item valueForKey:key]];
					}
					else if (NSOrderedSame == [type compare:@"time"]) {
						
						value = [[Globals sharedInstance].timeFormatter stringFromDate:[item valueForKey:key]];
					}
					
					textField.text = value;
				}
			}
			
			
		}
		@catch (NSException * e) {
			NSLog(@"Exception setting property = %@", [e name]);
		}
	}
}


- (void)edit:(id)sender {
	
	NSString *name = [item valueForKey:@"name"];
	NSString *url = [NSString stringWithFormat:@"tt://home/edit/%@?id=%@", self.pageName, name];
	
	NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:item, @"data", name, @"id",  nil];
	[[TTNavigator navigator] openURL:url query:query animated:YES];	
}

- (void)removeAction:(id)sender {

	UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert", @"")
													 message:NSLocalizedString(@"Delete this item?", @"") delegate:self
										   cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
										   otherButtonTitles:NSLocalizedString(@"OK", @""), nil] autorelease];
	[alert show];
	
}

- (void)processDelete {
	
	ParabayAppDelegate *delegate = (ParabayAppDelegate *)[[UIApplication sharedApplication] delegate];
	[delegate auditDeletion:self.pageData.defaultEntityName withId:[self.item valueForKey:@"parabay_id"]];
	
	// Delete the managed object for the given index path
	[self.managedObjectContext deleteObject: self.item];		
	
	// Save the context.
	NSError *error = nil;
	if (![self.managedObjectContext save:&error]) {
		// Handle error
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
	[self.navigationController popViewControllerAnimated:YES];
}

- (id<UITableViewDelegate>)createDelegate {
	EntityDetailsDelegate *detailsDelegate = [[[EntityDetailsDelegate alloc] initWithController:self] autorelease];
	detailsDelegate.isReadOnly = self.isReadOnly;
	return detailsDelegate;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[self processDelete];
	}
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
		
	[[NSNotificationCenter defaultCenter] removeObserver:self name:DataSavedNotification object:nil];

	//crash: managedObjectContext etc shouldn't be freed here.
	[propertyEditors release];
    [super dealloc];
}

@end


@implementation EntityDetailsDelegate

@synthesize isReadOnly;

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 60;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {

    if(footerView == nil && (!self.isReadOnly)) {
		
        //allocate the view if it doesn't exist yet
        footerView  = [[UIView alloc] init];
		
        //we would like to show a gloosy red button, so get the image first
        UIImage *image = [[UIImage imageNamed:@"button_red.png"]
						  stretchableImageWithLeftCapWidth:8 topCapHeight:8];
		
        //create the button
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button setBackgroundImage:image forState:UIControlStateNormal];
		
        //the button should be as big as a table view cell
        [button setFrame:CGRectMake(10, 3, 300, 44)];
		
        //set title, font size and font color
        [button setTitle:@"Delete" forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		
        //set action of the button
        [button addTarget:self.controller action:@selector(removeAction:)
		 forControlEvents:UIControlEventTouchUpInside];
		
        //add the button to the view
        [footerView addSubview:button];
    }
	
    //return the view for the footer
    return footerView;
}
@end
