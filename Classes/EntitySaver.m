//
//  EntitySaver.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 06/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EntitySaver.h"
#import "Globals.h"
#import "JSON.h"
#import "MetadataService.h"
#import "ParabayAppDelegate.h"
#import "Reachability.h"
#import "PageData.h"

@interface EntitySaver ()

@property BOOL done;
// The autorelease pool property is assign because autorelease pools cannot be retained.
@property (nonatomic, assign) NSAutoreleasePool *importPool;

@end

@implementation EntitySaver

@synthesize persistentStoreCoordinator, entityDescription;
@synthesize done, importPool, pageData;
@synthesize insertionContext, pageName;
@synthesize saveService, results;


- (void)dealloc {
    TT_RELEASE_SAFELY(persistentStoreCoordinator);
    TT_RELEASE_SAFELY(insertionContext);
    [super dealloc];
}

- (NSMutableDictionary *) convertNSManagedObjectToDictionary: (NSManagedObject *)managedObject {
	
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat: @"yyyy-MM-dd'T'HH:mm"]; // 2009-02-01 19:50:41 PST		
	
	for(NSString *propertyName in pageData.defaultEntityProperties) {
				
		id value = [managedObject valueForKey:propertyName];
		if (value) {
			if ([value isKindOfClass:[NSDate class]]) {
				value = [formatter stringFromDate:value];
			}
			
			NSLog(@"Property=%@", propertyName);
			//skip images
			if (![value isKindOfClass:[NSData class]] && ![value isKindOfClass:[NSManagedObject class]] && ![value isKindOfClass:[UIImage class]]) {
				
				[dict setObject:value forKey:propertyName];
			}
			else {
				NSLog(@"Skipping image");
			}
		}	
	}
	
	[dict setObject:[managedObject valueForKey:@"parabay_id"] forKey:@"id"];
	[formatter release];
	
	return dict;
}

- (void)sendSaveRequest {

	if (!self.pageName)
		return;
	
	NSLog(@"Checking for updates: %@", self.pageName);
	
	pageData = [[MetadataService sharedInstance] getPageData:pageName forEditorPage:nil ];
		
	NSFetchRequest *req = [[NSFetchRequest alloc] init];
	[req setEntity:self.entityDescription];
	[req setFetchLimit:10];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"parabay_status = %d", RecordStatusUpdated];
	[req setPredicate:predicate];
	
	NSError *error = nil;
	results = [self.insertionContext executeFetchRequest:req error:&error];
	if ((error != nil) || (results == nil)) {
		NSLog(@"Error while fetching\n%@",
			  ([error localizedDescription] != nil)
			  ? [error localizedDescription] : @"Unknown Error");
	}
	
	if ([results count]>0) {
		
		NSLog(@"Found updates: %@ = %d", self.pageName, [results count]);
		
		NSMutableArray *itemsList = [[[NSMutableArray alloc] init] autorelease];
		for (NSManagedObject *item in results) {
			[itemsList addObject: [self convertNSManagedObjectToDictionary:item]];
		}
		
		NSLog(@"Items List=%@", itemsList);
		self.saveService = [[[SaveService alloc] init] autorelease];
		self.saveService.kind = pageData.defaultEntityName;
		self.saveService.items = itemsList;
		self.saveService.delegate = self;
		
		[self.saveService execute];
	}
	else {

		ParabayAppDelegate *delegate = (ParabayAppDelegate *)[[UIApplication sharedApplication] delegate];
		[delegate queueServerDeleteForPage:self.pageName];

		TTNetworkRequestStopped();
		done = YES;
	}
	
	[req release];
}

- (void) updateSaveStatus {
	
	if (results) {
		for(NSManagedObject *item in results) {
			[item setValue:[NSNumber numberWithInt:RecordStatusSynchronized] forKey: @"parabay_status"];
		}
		
		NSError *saveError = nil;
		NSAssert1([insertionContext save:&saveError], @"Unhandled error saving managed object context in saver thread: %@", [saveError localizedDescription]);	
		
	}			
}

/*
- (void)service:(BaseService *) service status: (ServiceStatus) status withResult: (NSDictionary *)data {
		

	TTNetworkRequestStopped();
	if (status == ServiceStatusSuccess) {
		
		[self updateSaveStatus];
		
		ParabayAppDelegate *delegate = (ParabayAppDelegate *)[[UIApplication sharedApplication] delegate];
		[delegate queueServerSaveForPage: self.pageName];
	}
	else {

		NSLog(@"Error synchronizing data to server");
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  self.pageName, @"pageName", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName: DataListLoadedNotification object:nil userInfo:dict];		
	}
	done = YES;
}
*/

- (void)main {
	
	NSAutoreleasePool *threadImportPool = [[NSAutoreleasePool alloc] init];	
	
    done = NO;
	NSLog(@"Start EntitySaver: %@", self.pageName);
	
	[self sendSaveRequest];

	do {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	} while (!done);
		
	ParabayAppDelegate *delegate = (ParabayAppDelegate *)[[UIApplication sharedApplication] delegate];
	[delegate dequeueImporter:self];
	
	TT_RELEASE_SAFELY(threadImportPool);
}

- (NSManagedObjectContext *)insertionContext {
	
    if (insertionContext == nil) {
        insertionContext = [[NSManagedObjectContext alloc] init];
        [insertionContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    }
    return insertionContext;
}

- (NSEntityDescription *)entityDescription {
	
    if (entityDescription == nil) {
        entityDescription = [[NSEntityDescription entityForName: pageData.defaultEntityName inManagedObjectContext:self.insertionContext] retain];
    }
    return entityDescription;
}


@end
