//
//  EntityListController.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 19/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EntityListController.h"
#import "EntityDetailsController.h"
#import "ParabayAppDelegate.h"
#import "Globals.h"
#import "MetadataService.h"
#import "PageData.h"
#import "JSON.h"
#import "Reachability.h"
#import <objc/runtime.h>
#import "LoadDataService.h"
#import "LoadLocationService.h"
#import "SaveService.h"
#import "DeleteService.h"
#import "LoadFileService.h"
#import "SaveFileService.h"

#define SAFE_PROPERTY_VALUE(__VALUE) ( (__VALUE) ? __VALUE: @"")
#define TRIM_STR_VALUE(__VALUE, __TRIM) ( ([__VALUE isKindOfClass:[NSString class]] && [__VALUE length] > __TRIM) ? [NSString stringWithFormat:@"%@...", [__VALUE substringToIndex: __TRIM]] : __VALUE)

static NSTimeInterval const kRefreshTimeInterval = 3600;

@implementation EntityListController

@synthesize managedObjectContext, fetchedResultsController, tableView, pageName, pageData, editController, pageMetadata, layout, propertyMetadatas, searchController, searchResultsController, searchFields, privateQueue;
@synthesize mobileLayout, entityMetadata, cellType, sectionKeyPath, sortDescList, toolbar, toolbarItems, statusButtonItem, activityButtonItem, refreshButtonItem, timer, isReadOnly, searchTerm, locationManager, indexField, sectionIndexes;
@synthesize gkSession, peerID;

- (void) initMetadata {

	searchTerm = nil;
	pageData = [[MetadataService sharedInstance] getPageData:pageName forEditorPage:nil ];
	
	sectionIndexes = [[NSMutableDictionary alloc] initWithCapacity:255];
	
	sectionKeyPath = PB_SAFE_COPY([pageData.listLayout objectForKey:@"sectionKeyPath"]);
	sortDescList = [pageData.listLayout objectForKey:@"sortDescriptors"];
	
	if (!sectionKeyPath || [sectionKeyPath length]==0)  {
		sectionKeyPath = nil;
	}

	if (!sortDescList || [sortDescList count] ==0 ) {
		sortDescList = [NSArray arrayWithObjects: @"name", nil];
	}
	sortDescList = [sortDescList copy];
	
	self.entityMetadata = pageData.defaultEntityName;
	self.pageMetadata = pageData.listPageMetadata;
	self.mobileLayout = pageData.listLayout;
	self.propertyMetadatas = pageData.defaultEntityProperties;
	
	self.cellType = PB_SAFE_COPY([pageData.listLayout objectForKey:@"panel"]);
	self.indexField = PB_SAFE_COPY([pageData.listLayout objectForKey:@"indexfield"]);
	
	//NSLog(@"Layout=%@", self.mobileLayout);
	
	self.isReadOnly = NO;
	NSNumber *readOnly = [pageData.listLayout objectForKey:@"readonly"];
	if (readOnly && [readOnly boolValue])  {
		self.isReadOnly = YES;
	}	
}

- (void)didReceiveMemoryWarning   
{  
	NSLog(@"ListView:didReceiveMemoryWarning");
    [super didReceiveMemoryWarning];  
} 

- (id)initWithViewMap:(NSString*)name query:(NSDictionary*)query {

	if (self = [super init]) {
				
		NSLog(@"ListView:init(%@)", name);
		self.pageName = name;				
		[self initMetadata];
							
		ParabayAppDelegate *delegate = (ParabayAppDelegate *) [[UIApplication sharedApplication] delegate];
		self.managedObjectContext = [delegate managedObjectContext];
					
		// Create the tableview.
		self.view = [[[UIView alloc] initWithFrame:TTApplicationFrame()] autorelease];
		self.tableView = [[[UITableView alloc] initWithFrame:TTApplicationFrame() style:UITableViewStylePlain] autorelease];
		self.tableView.delegate = self;
		self.tableView.dataSource = self;
		//self.variableHeightRows = YES;  
		self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.view addSubview:self.tableView];
		
		NSArray *nameComponents = [name componentsSeparatedByString:@"_"];
		self.title = [nameComponents objectAtIndex:1];
		
		if (!self.isReadOnly) {
			self.navigationItem.rightBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add:)];
		}
		
		// create the UIToolbar at the bottom of the view controller
		//
		toolbar = [UIToolbar new];
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSInteger theme = [defaults integerForKey:@"theme_preference"];
		
		if (theme == 2) {			
			toolbar.barStyle = UIBarStyleBlackTranslucent;
		}
		
		// size up the toolbar and set its frame
		[toolbar sizeToFit];
		CGFloat toolbarHeight = [toolbar frame].size.height;
		CGRect mainViewBounds = self.view.bounds;
		[toolbar setFrame:CGRectMake(CGRectGetMinX(mainViewBounds),
									 CGRectGetMinY(mainViewBounds) + CGRectGetHeight(mainViewBounds) - (toolbarHeight * 2.0) + 2.0,
									 CGRectGetWidth(mainViewBounds),
									 toolbarHeight)];
		
		UILabel* label = [[[UILabel alloc] init] autorelease];
		label.font = [UIFont systemFontOfSize:12];
		label.backgroundColor = [UIColor clearColor];
		label.textColor = [UIColor whiteColor];
		label.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.35];
		label.shadowOffset = CGSizeMake(0, -1.0);		
		
		TTActivityLabel* activity = [[[TTActivityLabel alloc] initWithStyle:TTActivityLabelStyleWhite] autorelease];
		activity.text = @"Loading...";
		activity.width = 120;
		[activity sizeToFit];		
	
		self.refreshButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
																			   target:self action:@selector(refresh:)];
		self.statusButtonItem = [[UIBarButtonItem alloc] initWithCustomView:label];		
		self.activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activity];	
		[self updateStatusText];
		
		self.toolbarItems = [NSMutableArray arrayWithObjects:	self.refreshButtonItem, 
							 [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																		   target:nil  action:nil],
							 statusButtonItem,
							 [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																		   target:nil  action:nil],
							 //[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize
							 //											   target:self action:@selector(connectNF:)],
							 self.editButtonItem,
							 nil];
		
		if (self.isReadOnly) {
			[self.toolbarItems removeLastObject];
		}
		
		[self.toolbar setItems:self.toolbarItems animated:NO];
		[self.view addSubview:toolbar];
				
		self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
		
		[self refreshIfNecessary];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataListLoadedNotificationReceived:) name:DataListLoadedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginNotificationReceived:) name:LoginDoneNotification object:nil];	
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadNotificationReceived:) name:DataListReloadNotification object:nil];
		
		self.searchFields = PB_SAFE_COPY([pageData.listLayout objectForKey:@"searchfields"]);
		if (searchFields) {
			
			UISearchBar* searchBar = [[[UISearchBar alloc] init] autorelease];
			[searchBar sizeToFit];
			
			searchController = [[UISearchDisplayController alloc]
								initWithSearchBar:searchBar contentsController:self];
			searchController.delegate = self;
			searchController.searchResultsDataSource = self;
			searchController.searchResultsDelegate = self;
			searchController.searchResultsTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;		
			self.tableView.tableHeaderView = searchController.searchBar;
		}

		[self fetch]; 

	}
	return self;
}

- (void) updateStatusText {

	UILabel* label = (UILabel *)self.statusButtonItem.customView;
	
	label.text = @"Not updated";
	NSString *key = [NSString stringWithFormat:kLastStoreUpdateKey, self.pageName];
	NSDate *lastUpdate = [[NSUserDefaults standardUserDefaults] objectForKey:key];		
	if (lastUpdate) {
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateStyle:kCFDateFormatterShortStyle];
		[dateFormatter setTimeStyle:kCFDateFormatterShortStyle];		
		label.text = [NSString stringWithFormat:@"Updated %@", [dateFormatter stringFromDate:lastUpdate]];
	}
	[label sizeToFit];
	
}

- (void)dataListLoadedNotificationReceived:(NSNotification *)aNotification {
	
	NSString *page = [[aNotification userInfo] valueForKey:@"pageName"];
	
	if (page) {
		if (NSOrderedSame == [page compare:self.pageName]) {
			
			if ([NSThread isMainThread]) {
				self.refreshButtonItem.enabled = YES;
				[self updateStatusText];
				[toolbarItems replaceObjectAtIndex:2 withObject:self.statusButtonItem];
				
				self.toolbar.items = self.toolbarItems;
				[self fetch];
				
			} else {
				[self performSelectorOnMainThread:@selector(dataListLoadedNotificationReceived:) withObject:aNotification waitUntilDone:NO];
				
			}			
		}
	}
}

- (void)reloadNotificationReceived:(NSNotification *)aNotification {
	
	NSLog(@"Reloading UI");	
	[self fetch];
}

- (void)loginNotificationReceived:(NSNotification *)aNotification {
	
	NSString *token = [[aNotification userInfo] valueForKey:@"UD_TOKEN"];
	
	if (token) {
		
		[self refresh:nil];
	}
}

- (void)refresh:(id)sender {		
	NetworkStatus status = [[Reachability sharedReachability] internetConnectionStatus];
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* token = [defaults objectForKey:@"UD_TOKEN"];
	
	if (NotReachable != status) {
		if (!token) {
		
			TTOpenURL(@"tt://login");
		}
		else {
		
			self.refreshButtonItem.enabled = NO;
			
			[toolbarItems replaceObjectAtIndex:2 withObject:self.activityButtonItem];
			self.toolbar.items = self.toolbarItems;
				
			if (NSOrderedSame == [self.pageName compare:@"Contacts_Contacts"]) {
				
				/*
				SaveFileService *dataLoader = [[[SaveFileService alloc] init] autorelease];
				dataLoader.privateQueue = self.privateQueue;
				[dataLoader sendSaveRequest];	
				
				LoadFileService *fileLoader = [[[LoadFileService alloc]init]autorelease];
				fileLoader.privateQueue = self.privateQueue;
				[fileLoader sendLoadRequestWithOffset:0];
				 */
			}

			/*
			LoadLocationService *locLoader = [[[LoadLocationService alloc] init] autorelease];
			locLoader.privateQueue = self.privateQueue;
			[locLoader sendLoadRequestWithOffset: 0];
			*/
			
			SaveService *saver = [[[SaveService alloc] init] autorelease];
			saver.privateQueue = self.privateQueue;
			[saver sendSaveRequest:self.pageName];
			
			DeleteService *remover = [[[DeleteService alloc]init] autorelease];
			remover.privateQueue = self.privateQueue;
			[remover sendDeleteRequest:self.pageName];
			
			LoadDataService *loader = [[[LoadDataService alloc] init] autorelease];
			loader.privateQueue = self.privateQueue;
			[loader sendLoadRequest:self.pageName withOffset:0];
			
			
			[self.privateQueue go];
		}
	}
}

- (void)queueDidFinish:(ASINetworkQueue *)queue
{
	NSLog(@"queueDidFinish: %d", [NSThread isMainThread]);
	self.refreshButtonItem.enabled = YES;
	[self updateStatusText];
	[toolbarItems replaceObjectAtIndex:2 withObject:self.statusButtonItem];
	
	self.toolbar.items = self.toolbarItems;	
	[self fetch];
}

- (void)refreshIfNecessary
{	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* token = [defaults objectForKey:@"UD_TOKEN"];
    BOOL disableAutoSync = [defaults boolForKey:@"disable_autosync_preference"];

	NetworkStatus status = [[Reachability sharedReachability] internetConnectionStatus];
	if (token && !disableAutoSync && NotReachable != status) {
		NSString *key = [NSString stringWithFormat:kLastStoreUpdateKey, self.pageName];
		NSDate *lastUpdate = [defaults objectForKey:key];
		
		if (lastUpdate == nil || -[lastUpdate timeIntervalSinceNow] > kRefreshTimeInterval)  {
			[self refresh: nil];
		}		
	}
}

- (NSString *)stringUniqueID {
	
	NSString *  result;
	CFUUIDRef   uuid;
	CFStringRef uuidStr;
	
	uuid = CFUUIDCreate(NULL);
	assert(uuid != NULL);
	uuidStr = CFUUIDCreateString(NULL, uuid);
	assert(uuidStr != NULL);
	result = [NSString stringWithFormat:@"%@", uuidStr];
	assert(result != nil);
	NSLog(@"UNIQUE ID %@", result);
	
	CFRelease(uuidStr);
	CFRelease(uuid);
	return result;
}

- (void)add:(id)sender {

	NSManagedObject *data = [NSEntityDescription insertNewObjectForEntityForName: self.entityMetadata inManagedObjectContext:self.managedObjectContext];
	NSString *name = [self stringUniqueID];
	[data setValue:name forKey:@"name"];
	[data setValue:name forKey:@"parabay_id"];
	
	NSString *url = [NSString stringWithFormat:@"tt://home/edit/%@", [self.pageName substringToIndex:([self.pageName length]-1) ] ];
	NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:data, @"data", name, @"id",  nil];
	[[TTNavigator navigator] openURL:url query:query animated:YES];
	
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    [super setEditing:editing animated:animated];
	[self.navigationItem setHidesBackButton:editing animated:YES];
	
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tblView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		NSFetchedResultsController *frc = self.fetchedResultsController;
		if (tblView == self.searchDisplayController.searchResultsTableView)
		{
			frc = self.searchResultsController;
		}
		
		NSManagedObject *obj = [frc objectAtIndexPath:indexPath];

		ParabayAppDelegate *delegate = (ParabayAppDelegate *)[[UIApplication sharedApplication] delegate];
		[delegate auditDeletion:self.entityMetadata withId:[obj valueForKey:@"parabay_id"]];
		
        // Delete the managed object for the given index path
		[self.managedObjectContext deleteObject: obj];		
		NSLog(@"del=%@", indexPath);
		
		// Save the context.
		NSError *error = nil;
		if (![self.managedObjectContext save:&error]) {
			// Handle error
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			exit(-1);  // Fail
		}
		
		//required to avoid crash on delete.
		[tblView reloadData];
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

- (void)viewDidAppear:(BOOL)animated {
	
	//NSLog(@"ListView:DidAppear");
    [super viewDidAppear: animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:self.managedObjectContext];
    [self fetch];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL useLocation = [defaults boolForKey:@"location_preference"];
	if (useLocation) {
		// Start the location manager.
		[[self locationManager] startUpdatingLocation];
	}

}

- (void)viewDidDisappear:(BOOL)animated {
	
	//NSLog(@"ListView:DidDisAppear");
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:self.managedObjectContext];
	
}

- (void)handleSaveNotification:(NSNotification *)aNotification {
	NSLog(@"handleSaveNotification");
    [self.managedObjectContext mergeChangesFromContextDidSaveNotification:aNotification];
    [self fetch];
}

- (void)dealloc {
	
	NSLog(@"ListView:Dealloc");
	
	[self.privateQueue cancelAllOperations];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:DataListLoadedNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:DataListReloadNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:LoginDoneNotification object:nil];		
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:self.managedObjectContext];
	
	[self.locationManager release];
	[self.toolbar release];	
	[self.toolbarItems release];
    [self.fetchedResultsController release];
    [self.managedObjectContext release];
    [super dealloc];
}

- (void)fetch {
		
	@synchronized(self) { 
		NSLog(@"Fetching data");

		NSError *error = nil;
		BOOL success = [self.fetchedResultsController performFetch:&error];
		NSAssert2(success, @"Unhandled error performing fetch at EntityListController.m, line %d: %@", __LINE__, [error localizedDescription]);
		[self.tableView reloadData];		

		[searchController.searchResultsTableView reloadData];
	}
}

- (NSFetchedResultsController *)fetchedResultsController {
	
	if (fetchedResultsController == nil) {
				
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:self.entityMetadata inManagedObjectContext:managedObjectContext];
		[fetchRequest setEntity: entity];
		
		NSString *filter = PB_SAFE_COPY([pageData.listLayout objectForKey:@"filter"]);
		if (filter) {
			
			NSPredicate *predicate = nil;
			if ([filter rangeOfString:@"@@today@@"].location != NSNotFound) {
				NSString *format = [filter stringByReplacingOccurrencesOfString:@"@@today@@" withString: @" %@"];
				NSTimeInterval secondsPerDay = 24 * 60 * 60;
				NSDate *yesterday = [[NSDate alloc]
									 initWithTimeIntervalSinceNow:-secondsPerDay];
				predicate =[NSPredicate predicateWithFormat:format, yesterday];
			}
			else {
				predicate = [NSPredicate predicateWithFormat:filter];
			}
			[fetchRequest setPredicate:predicate];
		}
		
		NSMutableArray *sortDescriptors = [[NSMutableArray alloc] init];
		NSString *sectionNameKeyPath = nil;
		if (sectionKeyPath && [sectionKeyPath length] > 0) {
			sectionNameKeyPath = sectionKeyPath;
		}
		
		for (NSString *descName in self.sortDescList) {
			NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:descName ascending:YES];
			[sortDescriptors addObject:sortDescriptor];
		}
		
		[fetchRequest setSortDescriptors:sortDescriptors];
		fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:sectionNameKeyPath
																				  cacheName: self.pageName];
		
		//note: this causes crashes during save on 3.0 sdk during save
		//fetchedResultsController.delegate = self;
				
	}  
    return fetchedResultsController;
}    

- (NSFetchedResultsController *)searchResultsController {
	
	if (searchResultsController == nil) {
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:self.entityMetadata inManagedObjectContext:managedObjectContext];
		[fetchRequest setEntity: entity];
		
		NSMutableArray *sortDescriptors = [[NSMutableArray alloc] init];
		NSString *sectionNameKeyPath = nil;
		if (sectionKeyPath && [sectionKeyPath length] > 0) {
			sectionNameKeyPath = sectionKeyPath;
		}
				
		for (NSString *descName in self.sortDescList) {
			NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:descName ascending:YES];
			[sortDescriptors addObject:sortDescriptor];
		}
		
		[fetchRequest setSortDescriptors:sortDescriptors];
		searchResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:sectionNameKeyPath
																				  cacheName: self.pageName];
		//do not uncomment this - unexpected crashes during save
		//searchResultsController.delegate = self;
		
		if (self.searchTerm !=nil) {
			
			NSMutableString *format = [NSMutableString stringWithFormat:@"%@ contains[cd] ", self.searchFields];
			[format appendString:@"%@"];
			NSPredicate *predicate =[NSPredicate predicateWithFormat:format, self.searchTerm];
			NSLog(@"Predicate = %@", [predicate description]);			

			[searchResultsController.fetchRequest setPredicate:predicate];
		}
		
		
	}  
    return searchResultsController;
} 

#pragma mark Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
	
	NSFetchedResultsController *frc = self.fetchedResultsController;
	if (table == self.searchDisplayController.searchResultsTableView)
	{
        frc = self.searchResultsController;
    }
	
    NSInteger count = [[frc sections] count];	
	if (!sectionKeyPath || [sectionKeyPath length] == 0) {
		if (count == 0) {
			count = 1;
		}
	}
	
	//NSLog(@"Number of sections:%d", count);
    return count;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
	
	NSFetchedResultsController *frc = self.fetchedResultsController;
	if (table == self.searchDisplayController.searchResultsTableView)
	{
        frc = self.searchResultsController;
    }
	
	NSArray *sections = [frc sections];
    if ([sections count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
        numberOfRows = [sectionInfo numberOfObjects];
    }
    
	//NSLog(@"Number of rows in section:%d = %d", section, numberOfRows);
    return numberOfRows;
}

- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section { 
	NSString *title = nil;
	
	NSFetchedResultsController *frc = self.fetchedResultsController;
	if (table == self.searchDisplayController.searchResultsTableView)
	{
        frc = self.searchResultsController;
    }
	
	if ([ [frc sections] count] > 0) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[frc sections] objectAtIndex:section];
		
		title = [sectionInfo name];
		if ([title length] > 10) 
			title = [title substringToIndex:10];
		else if ([title length] == 0)
			title = nil; 
	}
	
	return title;
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)table {
	
	if (self.indexField) {
		
		[sectionIndexes removeAllObjects];
		NSArray *sectionTitles = [fetchedResultsController sectionIndexTitles];
		
		NSUInteger i = 0;
		for (NSString *index in sectionTitles) {
			[sectionIndexes setObject:[NSNumber numberWithInt:i++] forKey:index];
		}
		return [TTTableViewDataSource lettersForSectionsWithSearch:NO summary:NO];
	}

    return nil; 
}

- (NSInteger)tableView:(UITableView *)table sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	
	NSLog(@"sectionForSectionIndexTitle=%@ @ %d", title, index);
	
	NSInteger section = 0;
	
	NSNumber *sectionIndex = [sectionIndexes valueForKey:title];
	if (sectionIndex) {
		section = [fetchedResultsController sectionForSectionIndexTitle:title atIndex:[sectionIndex intValue]];
	}
    return section;
}

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id)object {
	
	if (NSOrderedSame == [self.cellType compare:@"TTTableSubtextItem"]) {
		return [TTTableSubtextItemCell class];
	}
	else if (NSOrderedSame == [self.cellType compare:@"TTTableRightCaptionItem"]) {
		return [TTTableRightCaptionItemCell class];
	}
	else if (NSOrderedSame == [self.cellType compare:@"TTTableCaptionItem"]) {
		return [TTTableCaptionItemCell class];
	}
	else if (NSOrderedSame == [self.cellType compare:@"TTTableSubtitleItem"]) {
		return [TTTableSubtitleItemCell class];
	}
	else if (NSOrderedSame == [self.cellType compare:@"TTTableMessageItem"]) {
		return [TTTableMessageItemCell class];
	}
	else if (NSOrderedSame == [self.cellType compare:@"TTTableImageItem"]) {
		return [TTTableImageItemCell class];
	}
	else if (NSOrderedSame == [self.cellType compare:@"TTStyledTextTableItem"]) {
		return [TTStyledTextTableItemCell class];
	}
	else if (NSOrderedSame == [self.cellType compare:@"TTTableLinkedItem"]) {
		return [TTTableTextItemCell class];
	}
	else if (NSOrderedSame == [self.cellType compare:@"TTTableControl"]) {
		return [TTTableControlCell class];
	} else {
		return [TTTableTextItemCell class];
	}

	return [TTTableViewCell class];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSFetchedResultsController *frc = self.fetchedResultsController;
	if (table == self.searchDisplayController.searchResultsTableView)
	{
        frc = self.searchResultsController;
    }
	
	NSManagedObject *data = [frc objectAtIndexPath:indexPath];
	
	Class cellClass = [self tableView:tableView cellClassForObject:data];
	const char* className = class_getName(cellClass);
	NSString* identifier = [[NSString alloc] initWithBytesNoCopy:(char*)className
														  length:strlen(className)
														encoding:NSASCIIStringEncoding freeWhenDone:NO];
	
	UITableViewCell* cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifier];
	if (cell == nil) {
		cell = [[[cellClass alloc] initWithStyle:UITableViewCellStyleDefault
								 reuseIdentifier:identifier] autorelease];
	}
	[identifier release];
	
	[self configureCell:cell atIndexPath: indexPath forTableView: table];	
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)table {
	
	NSFetchedResultsController *frc = self.fetchedResultsController;
	if (table == self.searchDisplayController.searchResultsTableView)
	{
        frc = self.searchResultsController;
    }
	
    // Configure the cell
	NSManagedObject *data = (NSManagedObject *)[frc objectAtIndexPath:indexPath];
	
	if ([cell isKindOfClass:[TTTableViewCell class]]) {
		
		TTTableItem *object = [self  tableItemForCellClass:[cell class] withData: data];		
		if (object)
			[(TTTableViewCell*)cell setObject:object];
	}	
}

- (TTTableItem *)tableItemForCellClass:(Class)klazz withData: (NSManagedObject *)data {
	
	TTTableItem *object = nil;
	
	if (data) {
		
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];		
		NSArray *fields = [self.mobileLayout objectForKey:@"fields"];		
		
		for(NSDictionary *field in fields) {
			NSString *type = [field objectForKey:@"type"];
			
			NSDictionary *params = [field objectForKey:@"params"];
			NSString *propertyName = [params objectForKey:@"data"];
						
			NSDictionary *entityPropertyMetadata = [self.propertyMetadatas valueForKey:propertyName];
			if (!entityPropertyMetadata)
				continue;
			
			NSString *dataType = [entityPropertyMetadata objectForKey:@"type_info"];
			
			id value = nil;			
			if (NSOrderedSame == [dataType compare:@"date"]) {
				
				NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
				[dateFormatter setDateStyle:kCFDateFormatterShortStyle];
				[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
				
				value = [dateFormatter stringFromDate:[data valueForKey: propertyName]];
			} else if (NSOrderedSame == [dataType compare:@"time"]) {
				
				NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
				[dateFormatter setDateStyle:NSDateFormatterNoStyle];
				[dateFormatter setTimeStyle: kCFDateFormatterShortStyle];
				
				value = [dateFormatter stringFromDate:[data valueForKey: propertyName]];
			} else if (NSOrderedSame == [dataType compare:@"image"]) {
				UIImage *image = [[Globals sharedInstance] thumbnailForProperty:propertyName inItem: data];
				[dict setObject:image forKey:type];
				continue;
			}
			else {
				value = [[data valueForKey: propertyName] description];
			}
			
			//NSLog(@"Property=%@, dataType=%@", propertyName, dataType);
			
			NSString *oldValue = [dict valueForKey:type];
			if (oldValue) 
				value = [oldValue stringByAppendingFormat:@" %@", value];
			
			if (value) {
				[dict setObject:SAFE_PROPERTY_VALUE(value) forKey:type];
			}
		}
		
		NSString *defaultURL = @"";
		if (self.isReadOnly) {
			defaultURL = nil;
		}
		
		//NSLog(@"dict=%@", dict);
		if ([klazz isEqual:[TTTableMessageItemCell class]]) {
			TTTableMessageItem *item = [[[TTTableMessageItem alloc] init] autorelease];
			item.title = SAFE_PROPERTY_VALUE([NSString stringWithFormat: [dict valueForKey:@"title"]]);
			item.caption = TRIM_STR_VALUE(SAFE_PROPERTY_VALUE([dict valueForKey:@"caption"]), 32);
			item.timestamp = [NSDate date]; //SAFE_PROPERTY_VALUE([dict valueForKey:@"timestamp"]);
			item.text = TRIM_STR_VALUE(SAFE_PROPERTY_VALUE([dict valueForKey:@"text"]), 80);
			item.URL = defaultURL;			
			object = item;
		}
		else if ([klazz isEqual:[TTTableCaptionItemCell class]]) {
			TTTableCaptionItem *item = [[[TTTableCaptionItem alloc] init] autorelease];
			item.caption = SAFE_PROPERTY_VALUE([dict valueForKey:@"caption"]);
			item.text = SAFE_PROPERTY_VALUE([dict valueForKey:@"title"]);
			item.URL = defaultURL;
			object = item;
		}
		else if ([klazz isEqual:[TTTableSubtitleItemCell class]]) {
			TTTableSubtitleItem *item = [[[TTTableSubtitleItem alloc] init] autorelease];
			item.subtitle = SAFE_PROPERTY_VALUE([dict valueForKey:@"subtitle"]);
			item.text = TRIM_STR_VALUE(SAFE_PROPERTY_VALUE([dict valueForKey:@"text"]), 32);
			item.URL = defaultURL;
			object = item;
		}
		else if ([klazz isEqual:[TTTableSubtextItemCell class]]) {
			TTTableSubtextItem *item = [[[TTTableSubtextItem alloc] init] autorelease];
			item.caption = SAFE_PROPERTY_VALUE([dict valueForKey:@"caption"]);
			item.text = SAFE_PROPERTY_VALUE([dict valueForKey:@"title"]);
			item.URL = defaultURL;
			object = item;
		}
		else if ([klazz isEqual:[TTTableImageItemCell class]]) {

			NSString *text = TRIM_STR_VALUE(SAFE_PROPERTY_VALUE([dict valueForKey:@"title"]), 32);
			UIImage *image = [dict valueForKey:@"image"];
			
			TTTableImageItem *item = [TTTableImageItem itemWithText:text imageURL:@""
							  defaultImage:image imageStyle:TTSTYLE(rounded)
									   URL:nil];
			object = item;
		}
		else if ([klazz isEqual:[TTTableTextItemCell class]]) {
			TTTableTextItem *item = [[[TTTableTextItem alloc] init] autorelease];
			item.text = TRIM_STR_VALUE(SAFE_PROPERTY_VALUE([dict valueForKey:@"title"]), 32);
			item.URL = defaultURL;
			object = item;
		}
		[dict release];
	}
	
	return object;
}

- (CGFloat)tableView:(UITableView*)tblView heightForRowAtIndexPath:(NSIndexPath*)indexPath {

	NSFetchedResultsController *frc = self.fetchedResultsController;
	if (tblView == self.searchDisplayController.searchResultsTableView)
	{
        frc = self.searchResultsController;
    }
	
	NSManagedObject *data = [frc objectAtIndexPath:indexPath];
	
	Class cls = [self tableView:tblView cellClassForObject:data];
	TTTableItem *object = [self tableItemForCellClass: cls withData:data];
	return [cls tableView:tblView rowHeightForObject:object];
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSFetchedResultsController *frc = self.fetchedResultsController;
	if (table == self.searchDisplayController.searchResultsTableView)
	{
        frc = self.searchResultsController;
    }
	
    [table deselectRowAtIndexPath:indexPath animated:YES];
	
    NSManagedObject *data = [frc objectAtIndexPath:indexPath];
	
	NSString *name = [data valueForKey:@"name"];
	NSString *url = [NSString stringWithFormat:@"tt://home/view/%@?id=%@", [self.pageName substringToIndex:([self.pageName length]-1) ], name ];
	NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:data, @"data", name, @"id", nil];
	[[TTNavigator navigator] openURL:url query:query animated:YES];
	
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{    
	self.searchTerm = searchString;
	self.searchResultsController = nil;
	
	NSError *error = nil;
	BOOL success = [self.searchResultsController performFetch:&error];
	NSAssert2(success, @"Unhandled error performing fetch at EntityListController.m, line %d: %@", __LINE__, [error localizedDescription]);		
	
	// Return YES to cause the search result table view to be reloaded.
	return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

#pragma mark -
#pragma mark Location manager

/**
 Return a location manager -- create one if necessary.
 */
- (CLLocationManager *)locationManager {
	
    if (locationManager != nil) {
		return locationManager;
	}
	
	locationManager = [[CLLocationManager alloc] init];
	[locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
	[locationManager setDelegate:self];
	
	return locationManager;
}


/**
 If the location manager is generating updates, then enable the button;
 If the location manager is failing, then disable the button.
 */
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
	
	CLLocationCoordinate2D coordinate = [newLocation coordinate];
	NSNumber *latitude	= [NSNumber numberWithDouble:coordinate.latitude];
	NSNumber *longitude = [NSNumber numberWithDouble:coordinate.longitude];
	
	NSLog(@"Location = (%@, %@)", latitude, longitude);
	[[self locationManager] stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
	NSLog(@"Failed to get location: %@", [error localizedDescription]);
}

/**
 Delegate methods of NSFetchedResultsController to respond to additions, removals and so on.
 */

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	
	UITableView *table = self.tableView;
	if (controller != self.fetchedResultsController) {
		table = self.searchDisplayController.searchResultsTableView;
	}
	
	// The fetch controller is about to start sending change notifications, so prepare the table view for updates.
	//[table beginUpdates];
}

/*
 enum {
 NSFetchedResultsChangeInsert = 1,
 NSFetchedResultsChangeDelete = 2,
 NSFetchedResultsChangeMove = 3,
 NSFetchedResultsChangeUpdate = 4
 
 }; 
*/
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	
	UITableView *table = self.tableView;
	if (controller != self.fetchedResultsController) {
		table = self.searchDisplayController.searchResultsTableView;
	}
	
	NSLog(@"changed row=%@->%@, type=%d", indexPath, newIndexPath, type);
	
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[table insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[table deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeUpdate: 
			[self configureCell:[table cellForRowAtIndexPath:indexPath] atIndexPath:indexPath forTableView:table];
			break;
			
		case NSFetchedResultsChangeMove:
			[table deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			// Reloading the section inserts a new row and ensures that titles are updated appropriately.
			[table reloadSections:[NSIndexSet indexSetWithIndex:newIndexPath.section] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	
	UITableView *table = self.tableView;
	if (controller != self.fetchedResultsController) {
		table = self.searchDisplayController.searchResultsTableView;
	}	
	
	NSLog(@"changed section=%d, type=%d", sectionIndex, type);
	
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[table insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[table deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	
	UITableView *table = self.tableView;
	if (controller != self.fetchedResultsController) {
		table = self.searchDisplayController.searchResultsTableView;
	}
	
	// The fetch controller has sent all current change notifications, so tell the table view to process all updates.
	//[table endUpdates];
}

- (ASINetworkQueue *)privateQueue {
	
	if (privateQueue == nil) {
		privateQueue = [[ASINetworkQueue alloc] init]; 
		[privateQueue setMaxConcurrentOperationCount:1];
		[privateQueue setShouldCancelAllRequestsOnFailure:NO];
		[privateQueue setDelegate:self];
		[privateQueue setQueueDidFinishSelector:@selector(queueDidFinish:)];
	}
	return privateQueue;
}

- (void)connectNF:(id)sender {		
	
	GKPeerPickerController *peerPickerController = [[GKPeerPickerController alloc] init];
	peerPickerController.delegate = self;
	peerPickerController.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
	[peerPickerController show];

}

- (void)sendNF:(id)sender {		
	

	 NSMutableData *message = [[NSMutableData alloc] init];
	 NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]
	 initForWritingWithMutableData:message];
	 [archiver encodeBool:YES forKey:@"test"];
	 [archiver finishEncoding];
	 NSError *sendErr = nil;
	 [gkSession sendDataToAllPeers: message
	 withDataMode:GKSendDataReliable error:&sendErr];
	 if (sendErr)
		 NSLog (@"send greeting failed: %@", sendErr);
	 
	 [message release];
	 [archiver release];

}

#pragma mark GKPeerPickerControllerDelegate methods

//START:code.P2PTapWarViewController.sessionforconnectiontype
-(GKSession*) peerPickerController: (GKPeerPickerController*) controller 
		  sessionForConnectionType: (GKPeerPickerConnectionType) type {
	
	if (!gkSession) {
		gkSession = [[GKSession alloc]
					 initWithSessionID:AMIPHD_P2P_SESSION_ID
					 displayName:nil
					 sessionMode:GKSessionModePeer];
		gkSession.delegate = self;
	}
	return gkSession;
}
//END:code.P2PTapWarViewController.sessionforconnectiontype


- (void)peerPickerController:(GKPeerPickerController *)picker
			  didConnectPeer:(NSString *)peerIDParam toSession:(GKSession *)session {
	
	NSLog ( @"connected to peer %@", peerIDParam);
		
	[session retain]; 	 // TODO: who releases this?
	[picker dismiss];
	[picker release];
}

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker {
	NSLog ( @"peer picker cancelled");
	[picker release];
}


#pragma mark GKSessionDelegate methods

//START:code.P2PTapWarViewController.peerdidchangestate
- (void)session:(GKSession *)session peer:(NSString *)peerIDParam
 didChangeState:(GKPeerConnectionState)state {
    switch (state) 
    { 
        case GKPeerStateConnected: 
			[session setDataReceiveHandler: self withContext: nil]; 
			peerID = [peerIDParam copy];
			isConnected = YES;
			
			//actingAsHost ? [self hostGame] : [self joinGame];
			break; 
    } 
}
//END:code.P2PTapWarViewController.peerdidchangestate


//START:code.P2PTapWarViewController.didreceiveconnectionrequestfrompeer
- (void)session:(GKSession *)session
didReceiveConnectionRequestFromPeer:(NSString *)peerID {
	actingAsHost = NO;
}
//END:code.P2PTapWarViewController.didreceiveconnectionrequestfrompeer

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {
	NSLog (@"session:connectionWithPeerFailed:withError:");	
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error {
	NSLog (@"session:didFailWithError:");		
}

# pragma mark receive data from session

/* receive data from a peer. callbacks here are set by calling
 [session setDataHandler: self context: whatever];
 when accepting a connection from another peer (ie, when didChangeState sends GKPeerStateConnected)
 */
//START:code.P2PTapWarViewController.receivedatafrompeerinsessioncontext
- (void) receiveData: (NSData*) data fromPeer: (NSString*) peerID
		   inSession: (GKSession*) session context: (void*) context {
	NSKeyedUnarchiver *unarchiver =
	[[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	if ([unarchiver containsValueForKey:@"test"]) {
	}
	[unarchiver release];
}
//END:code.P2PTapWarViewController.receivedatafrompeerinsessioncontext

/*
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	// create the parent view that will hold header Label
	UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(10.0, 0.0, 300.0, 30.0)];
	[customView setBackgroundColor:[UIColor lightGrayColor]];
	
	// create the button object
	UILabel * headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	headerLabel.backgroundColor = [UIColor lightGrayColor];
	headerLabel.opaque = NO;
	headerLabel.textColor = [UIColor blackColor];
	headerLabel.highlightedTextColor = [UIColor whiteColor];
	headerLabel.font = [UIFont systemFontOfSize:10.0];
	headerLabel.frame = CGRectMake(10.0, 0.0, 300.0, 25.0);
	
	// If you want to align the header text as centered
	// headerLabel.frame = CGRectMake(150.0, 0.0, 300.0, 44.0);
	
	headerLabel.text = @"tesst";// i.e. array element
	[customView addSubview:headerLabel];
	
	return customView;
}
*/

@end