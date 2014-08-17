//
//  ParabayAppDelegate.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 17/08/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "ParabayAppDelegate.h"
#import "TabBarController.h"
#import "AboutController.h"
#import "LoginUserController.h"
#import "RegisterUserController.h"
#import "HomeController.h"
#import "EntitySchema.h"
#import "EntityListController.h"
#import "MetadataService.h"
#import "EntityDetailsController.h"
#import "TextEditorController.h"
#import "DatePickerController.h"
#import "ListPickerController.h"
#import "EntityEditorController.h"
#import "LoadMetadataController.h"
#import "ParabayPhotoViewController.h"

#import "AdMobView.h"
#import "MapViewController.h"
#import "ImagePickerController.h"
#import "ASIFormDataRequest.h"
#import "Airship.h"
#import "StoreFront.h"
#import "ParabayStyleSheet.h"
#import "Reachability.h"

//Production keys
#define kApplicationKey @"Cfwn1otKQ8m8g20RtQZWIw"
#define kApplicationSecret @"aKYsOYjLSt-KQXQcb5bhMA"
//Test keys
//#define kApplicationKey @"skDMWRt2SkC27yiX7Rhp1g"
//#define kApplicationSecret @"apnPdkC-RbitsnK2elxDlw"

static NSTimeInterval const kRefreshTimeInterval = 3600;
static NSTimeInterval const kDeviceTokenRefreshTimeInterval = 3600*3;

@implementation ParabayAppDelegate

@synthesize window, progressOverlay, progressMessage, importers, adHostView, delEntityDescription, deviceToken, deviceAlias;


#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {    

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

#if TARGET_IPHONE_SIMULATOR == 0
	NSString *logPath = [ [self applicationDocumentsDirectory] stringByAppendingPathComponent: kLogFilePath];
    freopen([logPath fileSystemRepresentation], "w", stderr);
#endif
		
	// Allow HTTP response size to be unlimited.
    [[TTURLRequestQueue mainQueue] setMaxContentLength:0];
	[[TTURLCache sharedCache] setMaxPixelCount:10*320*480];
	
	[TTStyleSheet setGlobalStyleSheet:[[[ParabayStyleSheet alloc] init] autorelease]];
	
    // Override point for customization after app launch    
	TTNavigator* navigator = [TTNavigator navigator];
	navigator.window = window; 
	
	TTURLMap* map = navigator.URLMap;
	
	// Any URL that doesn't match will fall back on this one, and open in the web browser
	[map from:@"*" toViewController:[TTWebController class]];

	[map from:@"tt://home" toSharedViewController:[TabBarController class]];	
	[map from:@"tt://home/about" toSharedViewController:[AboutController class]];
	[map from:@"tt://home/menu/(initWithName:)" toSharedViewController:[HomeController class]];
	[map from:@"tt://home/list/(initWithViewMap:)" toViewController:[EntityListController class]];
	[map from:@"tt://home/view/(initWithViewMap:)" toViewController:[EntityDetailsController class]];
	[map from:@"tt://home/edit/(initWithViewMap:)" toViewController:[EntityEditorController class] transition:UIViewAnimationTransitionCurlUp];
	[map from:@"tt://login" toSharedViewController:[LoginUserController class]];
	[map from:@"tt://register" toSharedViewController:[RegisterUserController class] ];
	[map from:@"tt://home/edit/text/(initWithProperty:)" toViewController:[TextEditorController class]];
	[map from:@"tt://home/edit/date/(initWithProperty:)" toViewController:[DatePickerController class]];
	[map from:@"tt://home/edit/picker/(initWithProperty:)" toViewController:[ListPickerController class]];
	[map from:@"tt://map" toViewController:[MapViewController class]];
	[map from:@"tt://home/view/image/(initWithProperty:)" toViewController:[ParabayPhotoViewController class]];
	[map from:@"tt://load/metadata" toSharedViewController:[LoadMetadataController class]];
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];	
	[dateFormatter setDateFormat:@"yyyy"];
	int year = [[dateFormatter stringFromDate:[NSDate date]] intValue];
	
	if (year >= 2011) {
		TTAlert(@"This beta program is no longer suppported. Please update from appstore.");
	}
	
	[self migrateStoreIfRequired];	
	[self registerDeviceIfNecessary];
	
	NSInteger theme = [defaults integerForKey:@"theme_preference"];	
	if (theme == 2) {
		UIApplication* app = [UIApplication sharedApplication];
		[app setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];		
	}
	
	BOOL storeDisabled = [defaults boolForKey:@"disable_store_preference"];
	if (!storeDisabled) {
		[Airship takeOff: kApplicationKey identifiedBy: kApplicationSecret];
		[[StoreFront shared] setDelegate: self];
	}
			
    BOOL updateMetdata = [defaults boolForKey:@"updateapp_preference"];
	if (updateMetdata) {
		
		TTOpenURL(@"tt://load/metadata");
		[defaults setBool:NO forKey:@"updateapp_preference"];
	}
	else {
		TTOpenURL(@"tt://home/menu/root");
		
		NSString* token = [defaults objectForKey:@"UD_TOKEN"];
		NSString *email = [defaults objectForKey:@"UD_EMAIL"];
		
		if (email && !token) {
			TTOpenURL(@"tt://login");
		}
		
	}
	
	/*
	 navigator.persistenceMode = TTNavigatorPersistenceModeNone; //TTNavigatorPersistenceModeAll;

	 if (![navigator restoreViewControllers]) {
		TTOpenURL(@"tt://home/menu/root");
	}
	*/
}

- (void)registerDeviceIfNecessary
{	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* token = [defaults objectForKey:@"UD_TOKEN"];
	BOOL alertDisabled = [defaults boolForKey:@"disable_alert_preference"];
	
	NetworkStatus status = [[Reachability sharedReachability] internetConnectionStatus];
	if (token && NotReachable != status) {
		NSDate *lastUpdate = [defaults objectForKey:kLastDeviceTokenUpdateKey];
		
		if (lastUpdate == nil || -[lastUpdate timeIntervalSinceNow] > kDeviceTokenRefreshTimeInterval)  {
			if (!alertDisabled) {
				[[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound];
			}
			else {
				[self pingServer:[BaseService sharedQueue]];
			}
			[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastDeviceTokenUpdateKey];			
		}		
	}
}

- (void) startAdQueryFromHostView: (UIView *)hostView {

	self.adHostView = hostView;
	
	// Request an ad
	adMobAd = [AdMobView requestAdWithDelegate:self]; // start a new ad request
	[adMobAd retain]; // this will be released when it loads (or fails to load)	
	
}

- (void) stopAdQueryFromHostView: (UIView *)hostView {
	
	if (self.adHostView == hostView) {
		self.adHostView = nil;
	}
}

- (NSDictionary *) entityPropertyMetadataForEntity: (NSString *)entityName withProperty: (NSString *)propertyName {
	
	NSDictionary *entityPropertyMetadata = nil;
	
	NSDictionary *entities = [self.managedObjectModel entitiesByName];
	NSEntityDescription *entity = [entities objectForKey:entityName];
	
	if (entity) {
		NSDictionary *properties = [entity propertiesByName];
		NSPropertyDescription *property = [properties objectForKey:propertyName];
		
		if (property) {
			entityPropertyMetadata = [property userInfo];
		}
	}
	return entityPropertyMetadata;
}

/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
	
    NSError *error = nil;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			// Handle error
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        } 
    }
	
	StoreFront* sf = [StoreFront shared];
	[[SKPaymentQueue defaultQueue] removeTransactionObserver: sf.sfObserver];
	[Airship land];
	
	[TTStyleSheet setGlobalStyleSheet:nil];
}


#pragma mark -
#pragma mark Saving

/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.
 */
- (IBAction)saveAction:(id)sender {
	
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
		// Handle error
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
		
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
		[managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [EntitySchema managedObjectModel];     
    return managedObjectModel;
}

- (NSString *)normalizedEmail {
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];	
	NSString *email = [defaults objectForKey:@"UD_EMAIL"];
	if (email) {	
		email = [[ [email stringByReplacingOccurrencesOfString:@"@" withString:@""] stringByReplacingOccurrencesOfString:@"." withString:@""] stringByAppendingFormat:@"%@", @".sqlite"] ;
	}
	return email;
}

- (NSString *)normalizedAppName {
	
	NSString *appName = [[Globals sharedInstance] appName];
	if (NSOrderedSame == [appName compare:kParabayDefaultApp]) {
		appName = @"";
	}
	return appName;
}

- (NSString *)persistentStorePath {
	
    if (persistentStorePath == nil) {

		NSString *documentsDirectory = [self applicationDocumentsDirectory];
		NSString *appName = [self normalizedAppName];
		
		NSString *storePath = [NSString stringWithFormat:@"%@", [ documentsDirectory stringByAppendingPathComponent: [NSString stringWithFormat:@"Parabay%@V%d.sqlite", appName, kCurrentSchemaVersion]] ];
		NSString *email = [self normalizedEmail];
		if (email) {	
			
			NSString *newDestPath = [NSString stringWithFormat:@"%@", [ documentsDirectory stringByAppendingPathComponent: [NSString stringWithFormat:@"%@V%d%@", appName, kCurrentSchemaVersion, email]]];				
			if ([[NSFileManager defaultManager] fileExistsAtPath: storePath]) {
				
				NSError *error = nil;
				BOOL storeMoveSuccess = [[NSFileManager defaultManager] moveItemAtPath:storePath toPath: newDestPath error:&error];
				if (!storeMoveSuccess)
					NSLog(@"Unhandled error moving dbfile %s at line %d: %@", __FUNCTION__, __LINE__, [error localizedDescription]);				
			}
			storePath = newDestPath;			
		}
		
		persistentStorePath = [storePath copy];
		NSLog(@"Store path=%@", persistentStorePath);
    }
	
	NSLog(@"Returning Store path=%@", persistentStorePath);
    return persistentStorePath;
}

- (void)migrateStoreIfRequired {
		
	NSString *documentsDirectory = [self applicationDocumentsDirectory];		
	NSString *newDestPath = [self persistentStorePath];
	NSString *email = [self normalizedEmail];
	
	//abort migration if latest database file exists already
	if ([[NSFileManager defaultManager] fileExistsAtPath: newDestPath]) {
		NSLog(@"Found latest database, no migration required.");
		return;
	}
	
	//set the stage	
	NSString *oldDefaultPath = [ documentsDirectory stringByAppendingPathComponent: kParabayData0];
	NSString *newDefaultPath = [ documentsDirectory stringByAppendingPathComponent: kParabayData1];
	
	if (email) {
		
		oldDefaultPath = [[ documentsDirectory stringByAppendingPathComponent: email] copy];
		newDefaultPath = [[ documentsDirectory stringByAppendingPathComponent: [NSString stringWithFormat:@"V1%@", email]] copy];		
	}
	
	if ([[NSFileManager defaultManager] fileExistsAtPath: oldDefaultPath]) {
		
		NSError *error = nil;
		BOOL storeMoveSuccess = [[NSFileManager defaultManager] moveItemAtPath:oldDefaultPath toPath: newDefaultPath error:&error];
		if (!storeMoveSuccess)
			NSLog(@"Unhandled error moving dbfile %s at line %d: %@", __FUNCTION__, __LINE__, [error localizedDescription]);
	}
	
	//check conditions for migration
	for (NSInteger  i=kCurrentSchemaVersion-1; i>0; i--) {
		
		NSString *appName = [self normalizedAppName];		
		NSString *dbPath = [ documentsDirectory stringByAppendingPathComponent: [NSString stringWithFormat:@"Parabay%@V%d.sqlite", appName, i] ];
		if (email) {
			dbPath = [[ documentsDirectory stringByAppendingPathComponent: [NSString stringWithFormat:@"%@V%d%@", appName, i, email]] copy];
		}
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: dbPath]) {
						
			if ([self migrateStore:[NSURL fileURLWithPath:dbPath] toUpdatedStore:[NSURL fileURLWithPath:newDestPath] fromVersion:i]) {
				
				NSError *error = nil;
				BOOL storeDeleteSuccess = [[NSFileManager defaultManager] removeItemAtPath:dbPath error:&error];
				if (!storeDeleteSuccess)
					NSLog(@"Unhandled error deleting dbfile %s at line %d: %@", __FUNCTION__, __LINE__, [error localizedDescription]);
			}	
			break;
		}
	}
}

- (BOOL)migrateStore:(NSURL *)storeURL toUpdatedStore:(NSURL *)dstStoreURL fromVersion:(NSInteger) oldVersion {
	
	NSLog(@"Migrating store(version=%d) from: %@ to: %@", oldVersion, [storeURL description], [dstStoreURL description]);
	
    NSError *error = nil;
	
	NSManagedObjectModel *model1 = [EntitySchema managedObjectModelForVersion:oldVersion];
	NSManagedObjectModel *model2 = [EntitySchema managedObjectModelForVersion:kCurrentSchemaVersion];
	
    NSMappingModel *mappingModel = [NSMappingModel inferredMappingModelForSourceModel:model1
																	 destinationModel:model2 error:&error];
    if (error) {
        NSString *message = [NSString stringWithFormat:@"Inferring failed %@ [%@]",
							 [error description], ([error userInfo] ? [[error userInfo] description] : @"no user info")];
        NSLog(@"Failure message: %@", message);
		
        return NO;
    }
	
    NSValue *classValue = [[NSPersistentStoreCoordinator registeredStoreTypes] objectForKey:NSSQLiteStoreType];
    Class sqliteStoreClass = (Class)[classValue pointerValue];
    Class sqliteStoreMigrationManagerClass = [sqliteStoreClass migrationManagerClass];
	
    NSMigrationManager *manager = [[sqliteStoreMigrationManagerClass alloc]
								   initWithSourceModel:model1 destinationModel:model2];
	
    if (![manager migrateStoreFromURL:storeURL type:NSSQLiteStoreType
							  options:nil withMappingModel:mappingModel toDestinationURL:dstStoreURL
					  destinationType:NSSQLiteStoreType destinationOptions:nil error:&error]) {
		
        NSString *message = [NSString stringWithFormat:@"Migration failed %@ [%@]",
							 [error description], ([error userInfo] ? [[error userInfo] description] : @"no user info")];
        NSLog(@"Failure message: %@", message);
		
        return NO;
    }
    return YES;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator == nil) {

        NSError *error = nil;
		
        NSURL *storeUrl = [NSURL fileURLWithPath:self.persistentStorePath];
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel]; 
		
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
								 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
		
        NSPersistentStore *persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:dict error:&error];
		
		if (!persistentStore) {
			
			NSDictionary *ui = [error userInfo];
			if (ui) {
				NSLog(@"%@:%s %@" , [self class], _cmd, [error localizedDescription]);
				for (NSError *suberror in [ui valueForKey:NSDetailedErrorsKey]) {
					NSLog(@"\t%@" , [suberror localizedDescription]);
				}
			} else {
				NSLog(@"%@:%s %@" , [self class], _cmd, [error localizedDescription]);
			}
			
			// remove the old store; easier than deleting every object
			if ([[NSFileManager defaultManager] fileExistsAtPath:self.persistentStorePath]) {

				BOOL oldStoreRemovalSuccess = [[NSFileManager defaultManager] removeItemAtPath:self.persistentStorePath error:&error];
				NSAssert3(oldStoreRemovalSuccess, @"Unhandled error removing persistent store in %s at line %d: %@", __FUNCTION__, __LINE__, [error localizedDescription]);
				
				persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error];
			}
			
		}
        NSAssert3(persistentStore != nil, @"Unhandled error adding persistent store in %s at line %d: %@", __FUNCTION__, __LINE__, [error localizedDescription]);
    }
    return persistentStoreCoordinator;
}

#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	
    return [[Globals sharedInstance] applicationDocumentsDirectory];
}

- (void) clearUserData {
	
	managedObjectContext = nil;
	managedObjectModel = nil;
	persistentStorePath = nil;
	persistentStoreCoordinator = nil;
}

// Notification posted by NSManagedObjectContext when saved.
- (void)serviceDidSave:(NSNotification *)saveNotification {
	
    if ([NSThread isMainThread]) {
        //[self.managedObjectContext mergeChangesFromContextDidSaveNotification:saveNotification]; //uncomment to crash a 3.0 build.
		
		//reload UI
		[[NSNotificationCenter defaultCenter] postNotificationName: DataListReloadNotification object:nil];
		
    } else {
        [self performSelectorOnMainThread:@selector(importerDidSave:) withObject:saveNotification waitUntilDone:NO];

    }
}

- (void) auditDeletion: (NSString *)entityName withId:  (NSString *)key {
	
	NSManagedObject *item = [[NSManagedObject alloc] initWithEntity:self.delEntityDescription insertIntoManagedObjectContext:self.managedObjectContext];
	[item setValue:entityName forKey: @"kind"];
	[item setValue:key forKey: @"key"];
	
	NSError *saveError = nil;
	NSAssert1([managedObjectContext save:&saveError], @"Unhandled error saving managed object context in import thread: %@", [saveError localizedDescription]);
	
}

- (NSEntityDescription *)delEntityDescription {
	
    if (delEntityDescription == nil) {
        delEntityDescription = [[NSEntityDescription entityForName: @"ParabayDeletions" inManagedObjectContext:self.managedObjectContext] retain];
    }
    return delEntityDescription;
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	
	[adMobAd release];
	[refreshTimer invalidate];
	
	[importers release];
    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];
	[persistentStorePath release];
    
	[window release];
	[super dealloc];
}


// Request a new ad. If a new ad is successfully loaded, it will be animated into location.
- (void)refreshAd:(NSTimer *)timer {
	[adMobAd requestFreshAd];
}

#pragma mark -
#pragma mark AdMobDelegate methods

- (NSString *)publisherId {
	return @"a14a9c599944568"; // this should be prefilled; if not, get it from www.admob.com
}

- (UIColor *)adBackgroundColor {
	UIColor *ret = [UIColor colorWithRed:0.498 green:0.565 blue:0.667 alpha:1]; // this should be prefilled; if not, provide a UIColor
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger theme = [defaults integerForKey:@"theme_preference"];
	
	if (theme == 2) {
		ret = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
	}
	
	return ret;
}

- (UIColor *)primaryTextColor {
	return [UIColor colorWithRed:1 green:1 blue:1 alpha:1]; // this should be prefilled; if not, provide a UIColor
}

- (UIColor *)secondaryTextColor {
	return [UIColor colorWithRed:1 green:1 blue:1 alpha:1]; // this should be prefilled; if not, provide a UIColor
}

- (BOOL)mayAskForLocation {
	return NO; // this should be prefilled; if not, see AdMobProtocolDelegate.h for instructions
}

// To receive test ads rather than real ads...
/*
 
 - (BOOL)useTestAd {
 return YES;
 }

 - (NSString *)testAdAction {
 return @"url"; // see AdMobDelegateProtocol.h for a listing of valid values here
 }
 */

// Sent when an ad request loaded an ad; this is a good opportunity to attach
// the ad view to the hierachy.
- (void)didReceiveAd:(AdMobView *)adView {
	NSLog(@"AdMob: Did receive ad");
	
	if (self.adHostView) {
		// get the view frame
		CGRect frame = self.adHostView.frame;
		
		// put the ad at the bottom of the screen
		adMobAd.frame = CGRectMake(0, frame.size.height - 48, frame.size.width, 48);
		
		[self.adHostView addSubview:adMobAd];
	}
	
	[refreshTimer invalidate];
	refreshTimer = [NSTimer scheduledTimerWithTimeInterval:AD_REFRESH_PERIOD target:self selector:@selector(refreshAd:) userInfo:nil repeats:YES];
	
}

// Sent when an ad request failed to load an ad
- (void)didFailToReceiveAd:(AdMobView *)adView {
	NSLog(@"AdMob: Did fail to receive ad");
	//[adMobAd release];
	adMobAd = nil;
	// we could start a new ad request here, but in the interests of the user's battery life, let's not
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)_deviceToken {

	// Get a hex string from the device token with no spaces or < >
	self.deviceToken = [[[[_deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""] 
						 stringByReplacingOccurrencesOfString:@">" withString:@""] 
						stringByReplacingOccurrencesOfString: @" " withString: @""];
	
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];	
    self.deviceAlias = [userDefaults stringForKey: @"_UADeviceAliasKey"];
		
	// We like to use ASIHttpRequest classes, but you can make this register call how ever you like
	// just notice that it's an http PUT
	NSString *UAServer = @"https://go.urbanairship.com";
	NSString *urlString = [NSString stringWithFormat:@"%@%@%@/", UAServer, @"/api/device_tokens/", self.deviceToken];
	NSURL *url = [NSURL URLWithString:  urlString];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	request.requestMethod = @"PUT";
	
	// Send along our device alias as the JSON encoded request body
	if(self.deviceAlias != nil && [self.deviceAlias length] > 0) {
		[request addRequestHeader: @"Content-Type" value: @"application/json"];
		[request appendPostData:[[NSString stringWithFormat: @"{\"alias\": \"%@\"}", self.deviceAlias]
								 dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	// Authenticate to the server
	request.username = kApplicationKey;
	request.password = kApplicationSecret;
	
	[request setDelegate:self];
	[request setDidFinishSelector: @selector(successMethod:)];
	[request setDidFailSelector: @selector(requestWentWrong:)];
	[[BaseService sharedQueue] addOperation:request];
		
	NSLog(@"Device Token: %@", self.deviceToken);
	[self pingServer:[BaseService sharedQueue]];
}


- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	
	NSLog(@"Error=%@", [error localizedDescription]);
	[self pingServer:[BaseService sharedQueue]];
}

- (void)successMethod:(ASIHTTPRequest *) request {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setValue: self.deviceToken forKey: @"_UALastDeviceToken"];
	[userDefaults setValue: self.deviceAlias forKey: @"_UALastAlias"];
}

- (void)requestWentWrong:(ASIHTTPRequest *)request {
	NSError *error = [request error];
	UIAlertView *someError = [[UIAlertView alloc] initWithTitle: 
							  @"Network error" message: @"Error registering with server"
													   delegate: self
											  cancelButtonTitle: @"Ok"
											  otherButtonTitles: nil];
	[someError show];
	[someError release];
	NSLog(@"ERROR: NSError query result: %@", error);
}

- (void)pingServer: (NSOperationQueue *) queue {
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* token = [defaults objectForKey:@"UD_TOKEN"];
	BOOL alertDisabled = [defaults boolForKey:@"disable_alert_preference"];
	
	if (!self.deviceToken) {
		self.deviceToken = @"";
	}
	NSString *UAServer = DEFAULT_HOST_ADDRESS;
	NSString *timeZone = [[NSTimeZone localTimeZone] name];
	
	NSString *urlString = [NSString stringWithFormat:@"%@/api/register_iphone/%@", UAServer, [[Globals sharedInstance] appName]];
	NSURL *url = [NSURL URLWithString:  urlString];
	NSLog(@"PingURL=%@", urlString);
	
	ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
	[request setPostValue:self.deviceToken forKey:@"devicetoken"];
	[request setPostValue:token forKey:@"token"];
	[request setPostValue:timeZone forKey:@"timezone"];
	[request setPostValue:[[NSNumber numberWithBool:!alertDisabled] stringValue] forKey:@"alert"];
	request.requestMethod = @"POST";
		
	[queue addOperation:request];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	
	NSLog(@"remote notification: %@",[userInfo description]);
	NSLog(@"%@", [userInfo objectForKey: @"aps"]);
	//	NSString *message = [userInfo descriptionWithLocale:nil indent:1];
	NSString* message =  [[userInfo objectForKey: @"aps"] objectForKey: @"alert"];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Parabay" message:message delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
    [alert show];
    [alert release];
    
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	NSLog(@"Application memory warning");
	
}

#pragma mark -
#pragma mark StoreFrontDelegate

-(void)productPurchased:(UAProduct*) product {
	UALOG(@"[StoreFrontDelegate] Purchased: %@ -- %@", product.productIdentifier, product.title);
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (NSOrderedSame == [product.productIdentifier compare:@"PC001CAL01"]) {
		[defaults setBool:YES forKey:@"noads_paid"];
	}
}

-(void)storeFrontDidHide {
	UALOG(@"[StoreFrontDelegate] StoreFront quit, do something with content");
}

-(void)storeFrontWillHide {
	UALOG(@"[StoreFrontDelegate] StoreFront will hide");
}

@end

