//
//  SyncService.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-12-09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SyncService.h"
#import "ParabayAppDelegate.h"

static SyncService *syncService;

@implementation SyncService

@synthesize syncEntityDescription;

+ (SyncService*) sharedInstance {
	
	if (!syncService) {
        syncService = [[SyncService alloc] init]; 
	}
	
    return syncService;
}

- (NSString *)userName {
	
	ParabayAppDelegate *delegate = (ParabayAppDelegate *) [[UIApplication sharedApplication] delegate];
	NSString *ret = [delegate normalizedEmail];
	if (!ret) {
		ret = @"";
	}
	
	return ret;
}
	
- (void) updateServerToken: (NSString *)serverToken forKind: (NSString *)kind {
	
	NSLog(@"Updating server token: %@ for %@", serverToken, kind);
	
	NSFetchRequest *req = [[NSFetchRequest alloc] init];
	[req setEntity:self.syncEntityDescription];
	[req setFetchLimit:10];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"kind = %d", kind];
	[req setPredicate:predicate];
	
	NSError *dataError = nil;
	NSArray *results = [self.insertionContext executeFetchRequest:req error:&dataError];
	if ((dataError != nil) || (results == nil)) {
		NSLog(@"Error while fetching\n%@",
			  ([dataError localizedDescription] != nil)
			  ? [dataError localizedDescription] : @"Unknown Error");
	}
	
	NSManagedObject *item = nil;
	if ([results count]==0) {		
		item = [[NSManagedObject alloc] initWithEntity:self.syncEntityDescription insertIntoManagedObjectContext:self.insertionContext];
	}
	else {
		item = [results objectAtIndex:0];
	}

	[item setValue:kind forKey: @"kind"];	
	[item setValue:serverToken forKey: @"serverSyncToken"];
	[item setValue:[NSDate date] forKey:@"parabay_updated"];
	
	[item setValue:[self userName] forKey: @"user"];
	
	NSError *saveError = nil;
	NSAssert1([self.insertionContext save:&saveError], @"Unhandled error saving managed object context in saver thread: %@", [saveError localizedDescription]);	
	
	[req release];
	
}

- (NSString *) fetchServerTokenForKind: (NSString *)kind  { 
		
	NSString *ret = nil;
	
	NSFetchRequest *req = [[NSFetchRequest alloc] init];
	[req setEntity:self.syncEntityDescription];
	[req setFetchLimit:1];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"kind = %@ and user = %@", kind, [self userName]];
	[req setPredicate:predicate];
	
	NSError *dataError = nil;
	NSArray *results = [self.insertionContext executeFetchRequest:req error:&dataError];
	if ((dataError != nil) || (results == nil)) {
		NSLog(@"Error while fetching\n%@",
			  ([dataError localizedDescription] != nil)
			  ? [dataError localizedDescription] : @"Unknown Error");
	}
	
	NSManagedObject *item = nil;
	if ([results count]>0) {
		
		item = [results objectAtIndex:0];
		ret = [item valueForKey:@"serverSyncToken"];
	}
	else {
		NSLog(@"Server token not found");
	}

	return ret;
}


- (NSEntityDescription *)syncEntityDescription {
	
    if (syncEntityDescription == nil) {
        syncEntityDescription = [[NSEntityDescription entityForName: @"ParabaySync" inManagedObjectContext:self.insertionContext] retain];
    }
    return syncEntityDescription;
}

@end
