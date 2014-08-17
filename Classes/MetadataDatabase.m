//
//  MetadataService.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 18/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MetadataDatabase.h"
#import "LoadRootViewMaps.h"
#import "Globals.h"
#import "MetadataCache.h"
#import "JSON.h"

static MetadataDatabase* SharedInstance;

@implementation MetadataDatabase

@synthesize cacheEntityDescription, databaseName, persistentStoreCoordinator;

+ (MetadataDatabase*)sharedInstanceWithDatabaseName: (NSString *)dbName {
	
	if (!SharedInstance || NSOrderedSame != [SharedInstance.databaseName compare:dbName]) {
        SharedInstance = [[MetadataDatabase alloc] init]; 
		SharedInstance.databaseName = [dbName copy];	
	}
	
    return SharedInstance;
}

- (id)init {
	if (self = [super init]) {
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subMetadataLoadedNotificationReceived:) name:SubMetadataLoadedNotification object:nil];
	}
	return self;
}

- (void)subMetadataLoadedNotificationReceived:(NSNotification *)aNotification {
	
	NSError *saveError = nil;
	
	NSString *key  = [[aNotification userInfo] valueForKey:@"key"];
	NSString *value = [[aNotification userInfo] valueForKey:@"value"];

	[self removeOldCacheEntries:key];
	
	MetadataCache *entry = [[MetadataCache alloc] initWithEntity:self.cacheEntityDescription insertIntoManagedObjectContext:self.managedObjectContext];	
	entry.key = key;
	entry.value = value;
	
	NSAssert1([self.managedObjectContext save:&saveError], @"Unhandled error saving managed object context in import thread: %@", [saveError localizedDescription]);
	
	[entry release];
	
}

- (void)refreshMetadataFromServer: (id<LoadMetadataDelegate>)callback {
	[LoadRootViewMaps loadAllWithDelegate:callback];
}

- (MetadataCache *)fetchCacheEntry:(NSString *)key {
	
	MetadataCache *entry = nil;
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:self.cacheEntityDescription];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(key = %@)", key];
	[request setPredicate:predicate];
	
	// Execute the fetch -- create a mutable copy of the result.
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
		// Handle the error.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail		
	}
	
	if ([mutableFetchResults count] > 0) {
		entry = [[mutableFetchResults objectAtIndex:0] retain];
	}
	
	[mutableFetchResults release];
	[request release];
	
	return entry;
}

- (void)removeOldCacheEntries:(NSString *)key {

	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:self.cacheEntityDescription];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(key = %@)", key];
	[request setPredicate:predicate];
	
	// Execute the fetch -- create a mutable copy of the result.
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
		// Handle the error.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail		
	}
	
	for(MetadataCache *entry in mutableFetchResults) {
		[managedObjectContext deleteObject:entry];
	}	
	
	[mutableFetchResults release];
	[request release];
	
}

- (NSMutableArray *)fetchDataQueries {
	
	NSMutableArray *dataQueries = [[NSMutableArray alloc] init];  
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:self.cacheEntityDescription];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"(key LIKE[c] %@)", [NSString stringWithFormat: @"/api/dataquery_metadata/%@/*", [[Globals sharedInstance] appName]]];
	[request setPredicate:predicate];
	
	// Execute the fetch -- create a mutable copy of the result.
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
		// Handle the error.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail		
	}
	
	for(MetadataCache *entry in mutableFetchResults) {
		[entry retain];
		NSString *value = [entry valueForKey:@"value"];
		NSDictionary *json = [value JSONValue]; 
		NSDictionary *dataQuery = [[json objectForKey:@"dataquery_metadata"] copy];
		
		if (dataQuery)
			[dataQueries addObject:dataQuery];
	}	
	
	[mutableFetchResults release];
	[request release];
	
	return dataQueries;
}

- (void)dumpCache {

	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:self.cacheEntityDescription];
	
	// Execute the fetch -- create a mutable copy of the result.
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
		// Handle the error.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail		
	}
	
	for(MetadataCache *entry in mutableFetchResults) {
		NSLog(@"CacheKey:%@, %@", entry.key, entry.value);
	}
	
	[mutableFetchResults release];
	[request release];
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
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
	NSString *dbFile = [NSString stringWithFormat:@"%@.sqlite", self.databaseName];
	NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent: dbFile];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// If the expected store doesn't exist, copy the default store.
	if (![fileManager fileExistsAtPath:storePath]) {
		
		NSLog(@"Copying default metadata store to: %@", storePath);
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:self.databaseName ofType:@"sqlite"];
		if (defaultStorePath) {
			[fileManager copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
		}
	}
	
	NSURL *storeUrl = [NSURL fileURLWithPath:storePath];	
	
	NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
        // Handle error
		NSAssert3(NO, @"Unhandled error adding persistent store in %s at line %d: %@", __FUNCTION__, __LINE__, [error localizedDescription]);
    }    
	
    return persistentStoreCoordinator;
}

- (NSEntityDescription *)cacheEntityDescription {
    if (cacheEntityDescription == nil) {
        cacheEntityDescription = [[NSEntityDescription entityForName:@"MetadataCache" inManagedObjectContext:self.managedObjectContext] retain];
    }
    return cacheEntityDescription;
}

#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	
    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];
    
	[super dealloc];
}


@end
