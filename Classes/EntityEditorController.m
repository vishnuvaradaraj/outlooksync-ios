//
//  EntityEditorController.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 30/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EntityEditorController.h"
#import "ParabayAppDelegate.h"
#import "MetadataService.h"
#import "SearchResultsModel.h"
#import "Reachability.h"
#import "PageData.h"
#import "JSON.h"

@implementation EntityEditorController


@synthesize item, pageName, pageData, entityDescription, managedObjectContext, propertyEditors, hasSaved;

- (void) initMetadata {
		
	self.hasSaved = NO;
	self.pageData = [[MetadataService sharedInstance] getPageData:nil forEditorPage:pageName];
	//NSLog(@"Page data=%@", pageData.editorLayout);
	
	NSArray *groups = [pageData.editorLayout objectForKey:@"groups"];		
	self.propertyEditors = [[NSMutableDictionary alloc] init];

	NSMutableArray *sections = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *items = [[[NSMutableArray alloc] init] autorelease];
	
	NSUInteger currentTag = 0;
	
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
			
			TTTableControlItem *tableItem = nil;
			
			if (NSOrderedSame == [type compare:@"text"]) {
				
				NSString *url = [NSString stringWithFormat:@"tt://home/edit/text/%@", propertyName];
				tableItem = [TTTableCaptionItem itemWithText:@"-" caption:propertyName URL:url];
				
			} else if (NSOrderedSame == [type compare:@"date"]) {
				
				NSString *url = [NSString stringWithFormat:@"tt://home/edit/date/%@?display=date", propertyName];
				tableItem = [TTTableCaptionItem itemWithText:@"-" caption:propertyName URL:url];
			} else if (NSOrderedSame == [type compare:@"time"]) {
				
				NSString *url = [NSString stringWithFormat:@"tt://home/edit/date/%@?display=time", propertyName];
				tableItem = [TTTableCaptionItem itemWithText:@"-" caption:propertyName URL:url];
			} else if (NSOrderedSame == [type compare:@"image"]) {
				
				tableItem = [TTTableImageItem itemWithText:propertyName imageURL:@" "
											  defaultImage:nil imageStyle:TTSTYLE(rounded)
													   URL:@"tt://home/edit/image"];
			} else {
				
				UIControl *control = nil;
				
				if (NSOrderedSame == [type compare:@"boolean"]) {
					UISwitch* switchy = [[[UISwitch alloc] init] autorelease];
					switchy.on = NO;
					
					control = switchy;
				}
				else {
					UITextField* textField = [[[UITextField alloc] init] autorelease];
					textField.placeholder = propertyName;
					textField.font = TTSTYLEVAR(font);
					textField.delegate = self;
					textField.tag = currentTag++;
					//NSLog(@"TextField:(%@)-%d", propertyName, currentTag);
					textField.returnKeyType = UIReturnKeyNext;
					textField.clearButtonMode = UITextFieldViewModeWhileEditing;		
					
					control = textField;
				}

				
				tableItem = [TTTableControlItem itemWithCaption:propertyName
														control:control];
			}
			
			tableItem.userInfo = [field retain];
			
			[sectionItems addObject:tableItem];
			[propertyEditors setObject:tableItem forKey: propertyName];
		}
	}
	
	self.dataSource = [TTSectionedDataSource dataSourceWithItems:items sections: sections];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(propertyEditorNotificationReceived:) name:PropertyEditorNotification object:nil];	
	[self.propertyEditors release];	
}

- (void)propertyEditorNotificationReceived:(NSNotification *)aNotification {
	
	NSString *key = [[aNotification userInfo] valueForKey:@"id"];
	NSString *page = [[aNotification userInfo] valueForKey:@"pageName"];
	
	if (key && page) {
		if ((NSOrderedSame == [page compare:self.pageName]) && 
			(NSOrderedSame == [key compare:[item valueForKey:@"name"] ])) {
			
			[self updateTextFields];
			[self.tableView reloadData];
		}
	}
}

- (void)setItem:(NSManagedObject*)aValue {
	
	if (item)  {
		[self updateTextFields];
		TT_RELEASE_SAFELY(item);
	}
	item = [aValue retain];
	
	for(NSString *key in self.propertyEditors) {
		
		@try {
			TTTableControlItem *tableItem = [self.propertyEditors objectForKey:key];
			NSDictionary *field = [tableItem userInfo];
			NSString *type = [field objectForKey:@"type"];
			
			if (NSOrderedSame == [type compare:@"text"]) {
				TTTableCaptionItem *captionItem = (TTTableCaptionItem *) tableItem;
				captionItem.text = @"-";
				
				if (item) {
					
					NSString *value = [[item valueForKey:key] description];
					if ([value length] == 0) {
						value = @"-";
					}
					else if ([value length] > 32) {
						value =  [NSString stringWithFormat: @"%@...", [value substringToIndex:32]];
					}
					
					captionItem.text = value;
				}
			} else if (NSOrderedSame == [type compare:@"date"]) {
				
				TTTableCaptionItem *captionItem = (TTTableCaptionItem *) tableItem;
				captionItem.text = @" ";
				
				if (item) {
					NSString *value = [[Globals sharedInstance].dateFormatter stringFromDate:[item valueForKey:key]];
					if ([value length] == 0) 
						value = @" ";
					captionItem.text = value;
				}
				
			} else if (NSOrderedSame == [type compare:@"time"]) {
				
				TTTableCaptionItem *captionItem = (TTTableCaptionItem *) tableItem;
				captionItem.text = @" ";
				
				if (item) {
					NSString *value = [[Globals sharedInstance].timeFormatter stringFromDate:[item valueForKey:key]];
					if ([value length] == 0) 
						value = @" ";
					captionItem.text = value;
				}
				
			} else if (NSOrderedSame == [type compare:@"boolean"]) {
				
				UISwitch *switchy = (UISwitch *)tableItem.control;
				switchy.on = [[item valueForKey:key] boolValue];
				
			} else if (NSOrderedSame == [type compare:@"image"]) {
				
				TTTableImageItem *imageItem = (TTTableImageItem *) tableItem;
				imageItem.defaultImage = [[Globals sharedInstance] thumbnailForProperty:key inItem: item];
				
			} else  {
				
				UITextField* textField = (UITextField *)tableItem.control;			
				if (item) {
					NSString *value = [[item valueForKey:key] description];
					textField.text = value;				
				}
			}
			
		}
		@catch (NSException * e) {
			NSLog(@"Exception setting property = %@", [e name]);
		}
	}
	
}

- (id)initWithViewMap:(NSString*)name query:(NSDictionary*)query {
	
	if (self = [super init]) {
		
		[[TTNavigator navigator].URLMap from:@"tt://home/edit/image"
									toObject:self selector:@selector(popupActionSheet)];
		
		self.hasSaved = NO;
		self.tableViewStyle = UITableViewStyleGrouped;
		self.autoresizesForKeyboard = YES;
		self.variableHeightRows = YES;
		self.navigationItem.rightBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
		
		pageName = [name copy];
		NSArray *nameComponents = [name componentsSeparatedByString:@"_"];
		self.title = [NSString stringWithFormat:@"Edit %@",  [nameComponents objectAtIndex:1]];
		
		[self initMetadata];
		
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
		entityDescription = [NSEntityDescription entityForName:pageData.defaultEntityName inManagedObjectContext:managedObjectContext];		
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
		NSArray *array = [managedObjectContext executeFetchRequest:req error:&error];
		if ((error != nil) || (array == nil)) {
			NSLog(@"Error while fetching\n%@",
				  ([error localizedDescription] != nil)
				  ? [error localizedDescription] : @"Unknown Error");
		}
		
		if ([array count] > 0) {
			ret = [array objectAtIndex:0];
		}else {
			ret = [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:managedObjectContext];
		}
		
		[req release];
		
	}
	
	return ret;
}

- (void)updateTextFields {

	for(NSString *key in self.propertyEditors) {
		
		TTTableControlItem *tableItem = [self.propertyEditors objectForKey:key];
		NSDictionary *field = [tableItem userInfo];
		NSString *type = [field objectForKey:@"type"];
		
		if (NSOrderedSame == [type compare:@"string"]) {
			
			UITextField* textField = (UITextField *)tableItem.control;			
			[item setValue:textField.text forKey:key];
		} 
		else if (NSOrderedSame == [type compare:@"boolean"]) {
			UISwitch *switchy = (UISwitch *)tableItem.control;
			[item setValue:[NSNumber numberWithBool:switchy.on] forKey:key];
			
		}
	}
}

- (void)save:(id)sender {
	
	self.hasSaved = YES;

	[self updateTextFields];
	[item setValue:[NSNumber numberWithInt:RecordStatusUpdated] forKey:@"parabay_status"];
	
	NSManagedObjectContext *context = item.managedObjectContext;
	NSError *error = nil;
	if (![context save:&error]) {
		// Handle error
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  self.pageName, @"pageName", [[item valueForKey:@"name"] copy], @"id", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: DataSavedNotification object:nil userInfo:dict];
	
	[self.navigationController popViewControllerAnimated:YES];
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
	
	[[TTNavigator navigator].URLMap removeURL:@"tt://home/edit/image"];
	
	if (!hasSaved) {
		ParabayAppDelegate *delegate = (ParabayAppDelegate *) [[UIApplication sharedApplication] delegate];	
		[[delegate managedObjectContext] rollback];
		
		//[[NSNotificationCenter defaultCenter] postNotificationName: DataListReloadNotification object:nil];
	}
	
	//crash: managedObjectContext etc shouldn't be freed here.
	[propertyEditors release];    
	[super dealloc];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [self updateTextFields];	
	
	[textField resignFirstResponder];	
	UIView *nextView = [self.view viewWithTag: textField.tag+1];
	if (nextView)
		[nextView becomeFirstResponder];
	
    return YES;
}

-(void)popupActionSheet {
		
	NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
	if (selectedRow) {
		[self.tableView deselectRowAtIndexPath:selectedRow animated:YES];
	}
	
	editingImageProperty = @"Photo";
    UIActionSheet *popupQuery = [[UIActionSheet alloc]
								 initWithTitle:nil
								 delegate:self
								 cancelButtonTitle:NSLocalizedString(@"Cancel", @"Image picker")
								 destructiveButtonTitle:nil
								 otherButtonTitles:nil];
	
	chooseExisting = 1;
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		[popupQuery addButtonWithTitle:@"Take Photo"];
		chooseExisting = 2;
	}
	[popupQuery addButtonWithTitle:NSLocalizedString(@"Choose Existing Photo", @"Photo picker")];
	
	/*
	NetworkStatus status = [[Reachability sharedReachability] internetConnectionStatus];
	if (NotReachable != status) {
		[popupQuery addButtonWithTitle:NSLocalizedString(@"Search On Server", @"Photo picker")];
	}
	*/
	
    [popupQuery showInView:self.view];
    [popupQuery release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex == 0) {
		NSLog(@"Cancel");
	}
	else if (buttonIndex <= chooseExisting) {
		
		// Choose existing photo
		UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
		imagePicker.sourceType = ((chooseExisting == 2 && buttonIndex == 1) ? UIImagePickerControllerSourceTypeCamera :  UIImagePickerControllerSourceTypePhotoLibrary);
		imagePicker.delegate = self;
		[self presentModalViewController:imagePicker animated:YES];
		[imagePicker release];	
		
	}
	else if (buttonIndex == chooseExisting+1) {
		
		SearchResultsModel *photoSource = [[SearchResultsModel alloc] init];	
		[photoSource setSearchTerms:@"nature"];    
		[photoSource setSource:SearchSourceYahoo];
		[photoSource load:TTURLRequestCachePolicyDefault more:NO];
		
		TTThumbsViewController *thumbs = [[TTThumbsViewController alloc] init];
		[thumbs setPhotoSource:photoSource];
		[self.navigationController pushViewController:thumbs animated:YES];
		[thumbs release];		
	}
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)selectedImage editingInfo:(NSDictionary *)editingInfo {	

	NSString *uuid = [[NSProcessInfo processInfo] globallyUniqueString];
	NSString *imageFilePath = [[Globals sharedInstance] imageFilePath:uuid];	

	/*
	UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
	HUD = [[MBProgressHUD alloc] initWithWindow:window];
	[window addSubview:HUD];
	HUD.delegate = self;
	HUD.labelText = @"Saving";
	[HUD showWhileExecuting:@selector(myTask) onTarget:self withObject:nil animated:YES];
	*/
	
	NSManagedObject *image = [self.item valueForKey: editingImageProperty];
	if (image == nil) {
		image = [NSEntityDescription insertNewObjectForEntityForName:@"ParabayImages" inManagedObjectContext:self.managedObjectContext];
	}
	
	UIImage *original = [[Globals sharedInstance] resizeImage:selectedImage withMaxSize: 320.0];
	NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(original)];
	[imageData writeToFile:imageFilePath atomically:YES];
	
	NSLog(@"Saving to path: %@", imageFilePath);
	
	[image setValue:uuid forKey:@"cacheFilePath"];
	[image setValue: [[Globals sharedInstance] resizeImage:selectedImage withMaxSize: 120.0] forKey:@"medium"];
	[image setValue: [[Globals sharedInstance] resizeImage:selectedImage withMaxSize: 44.0] forKey:@"thumbnail"];
	[image setValue: [NSNumber numberWithInt: RecordStatusUpdated] forKey:@"parabay_status"];
	
	NSError *error = nil;
	if (![self.managedObjectContext save:&error]) {
		NSLog(@"Unresolved error saving image: %@, %@", error, [error userInfo]);
	}

	[item setValue:image forKey: editingImageProperty];
	self.item = self.item;
	
	//[self.item setValue:UIImagePNGRepresentation([[Globals sharedInstance] resizeImage:selectedImage withMaxSize: 160.0]) forKey:editingImageProperty];
	[self dismissModalViewControllerAnimated:YES];
	[self.tableView reloadData];
		
}

- (void) myTask  {
	sleep(5);
}

- (void)hudWasHidden {
	// Remove HUD from screen when the HUD was hidded
	[HUD removeFromSuperview];
	[HUD release];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissModalViewControllerAnimated:YES];
}

@end
