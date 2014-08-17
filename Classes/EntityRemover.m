//
//  EntityRemover.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 07/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EntityRemover.h"
#import "Globals.h"
#import "JSON.h"
#import "MetadataService.h"
#import "ParabayAppDelegate.h"
#import "Reachability.h"
#import "PageData.h"

@interface EntityRemover ()

@property BOOL done;
// The autorelease pool property is assign because autorelease pools cannot be retained.
@property (nonatomic, assign) NSAutoreleasePool *importPool;

@end

@implementation EntityRemover

@synthesize persistentStoreCoordinator, pageData;
@synthesize done, delEntityDescription, importPool;
@synthesize insertionContext, pageName;
@synthesize deleteService, results;

- (void)dealloc {
	NSLog(@"Dealloc EntityRemover.");
    TT_RELEASE_SAFELY(persistentStoreCoordinator);
    TT_RELEASE_SAFELY(insertionContext);
    [super dealloc];
}

- (void)sendDeleteRequest {
	
	if (!self.pageName)
		return;
	
	NSLog(@"Checking for deletes: %@", self.pageName);
	
	pageData = [[MetadataService sharedInstance] getPageData:pageName forEditorPage:nil ];
	
	NSFetchRequest *req = [[NSFetchRequest alloc] init];
	[req setEntity:self.delEntityDescription];
	[req setFetchLimit:10];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"kind = %@", pageData.defaultEntityName];
	[req setPredicate:predicate];
	
	NSError *error = nil;
	results = [self.insertionContext executeFetchRequest:req error:&error];
	if ((error != nil) || (results == nil)) {
		NSLog(@"Error while fetching\n%@",
			  ([error localizedDescription] != nil)
			  ? [error localizedDescription] : @"Unknown Error");
	}
	
	if ([results count]>0) {
		
		NSMutableArray *ids = [[NSMutableArray alloc]init];
		for(NSManagedObject *item in results) {
			NSLog(@"Deleted audit: %@", [item valueForKey:@"key"]);
			[ids addObject: [[item valueForKey:@"key"] copy]];
		}
		
		NSLog(@"Deleting: %@", ids);
		
		self.deleteService = [[[DeleteService alloc] init] autorelease];
		self.deleteService.kind = pageData.defaultEntityName;
		self.deleteService.items = ids;
		self.deleteService.delegate = self;
		
		[self.deleteService execute];
	}
	else {
		
		ParabayAppDelegate *delegate = (ParabayAppDelegate *)[[UIApplication sharedApplication] delegate];
		[delegate queueImportForPage:self.pageName withOffset: 0];
		
		TTNetworkRequestStopped();
		done = YES;
	}
	
	[req release];
}

- (void) updateDeleteStatus {
	
	if (results) {
		for(NSManagedObject *item in results) {
			[insertionContext deleteObject:item];		
		}
		
		NSError *saveError = nil;
		NSAssert1([insertionContext save:&saveError], @"Unhandled error saving managed object context in saver thread: %@", [saveError localizedDescription]);	
		
		results = nil;
	}
	
}

/*
- (void)service:(BaseService *) service status: (ServiceStatus) status withResult: (NSDictionary *)data {
	
	NSLog(@"Delete service callback");
	
	TTNetworkRequestStopped();
	if (status == ServiceStatusSuccess) {
		
		[self updateDeleteStatus];
		
		ParabayAppDelegate *delegate = (ParabayAppDelegate *)[[UIApplication sharedApplication] delegate];
		[delegate queueServerDeleteForPage: self.pageName];	
	}
	else {
		NSLog(@"Error synchronizing data to server");
	}
	done = YES;
}
*/

- (void)main {
	
	NSAutoreleasePool *threadImportPool = [[NSAutoreleasePool alloc] init];	
	
    done = NO;
	NSLog(@"Start EntityRemover- %@", self.pageName);
		
	[self sendDeleteRequest];
	
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

- (NSEntityDescription *)delEntityDescription {
	
    if (delEntityDescription == nil) {
        delEntityDescription = [[NSEntityDescription entityForName: @"ParabayDeletions" inManagedObjectContext:self.insertionContext] retain];
    }
    return delEntityDescription;
}

@end
