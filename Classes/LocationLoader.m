//
//  LocationLoader.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-11-24.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LocationLoader.h"
#import "Globals.h"
#import "JSON.h"
#import "MetadataService.h"
#import "ParabayAppDelegate.h"
#import "Reachability.h"
#import "PageData.h"

@interface LocationLoader ()

@property BOOL done;
// The autorelease pool property is assign because autorelease pools cannot be retained.
@property (nonatomic, assign) NSAutoreleasePool *importPool;

@end

@implementation LocationLoader

@synthesize persistentStoreCoordinator, entityDescription;
@synthesize done, importPool;
@synthesize insertionContext;
@synthesize loadLocationService, results;


- (void)dealloc {
    TT_RELEASE_SAFELY(persistentStoreCoordinator);
    TT_RELEASE_SAFELY(insertionContext);
    [super dealloc];
}

- (void)sendLoadRequest {
	
	
	self.loadLocationService = [[[LoadLocationService alloc] init] autorelease];
	self.loadLocationService.delegate = self;
	
	[self.loadLocationService execute];
}

- (void) updateLocations {
	
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
		
		[self updateLocations];
		
		//ParabayAppDelegate *delegate = (ParabayAppDelegate *)[[UIApplication sharedApplication] delegate];
		//[delegate queueServerSaveForPage: self.pageName];
	}
	else {
		
		NSLog(@"Error synchronizing data to server");
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: nil];
		[[NSNotificationCenter defaultCenter] postNotificationName: DataListLoadedNotification object:nil userInfo:dict];		
	}
	done = YES;
}
*/

- (void)main {
	
	NSAutoreleasePool *threadImportPool = [[NSAutoreleasePool alloc] init];	
	
    done = NO;
	NSLog(@"Start LocationLoader");
	
	[self sendLoadRequest];
	
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
        entityDescription = [[NSEntityDescription entityForName: @"ParabayLocations" inManagedObjectContext:self.insertionContext] retain];
    }
    return entityDescription;
}


@end
