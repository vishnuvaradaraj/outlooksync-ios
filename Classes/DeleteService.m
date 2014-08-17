//
//  DeleteService.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 06/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DeleteService.h"
#import "Globals.h"
#import "JSON.h"
#import "PageData.h"

@implementation DeleteService

@synthesize items, kind, results, delEntityDescription;

- (BOOL)sendDeleteRequest: (NSString *)pageNameParam {
	
	BOOL ret = NO;
	
	NSLog(@"Checking for deletes: %@", pageNameParam);	
	self.pageName = pageNameParam;
	
	NSFetchRequest *req = [[NSFetchRequest alloc] init];
	[req setEntity:self.delEntityDescription];
	[req setFetchLimit:10];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"kind = %@", self.pageData.defaultEntityName];
	[req setPredicate:predicate];
	
	NSError *dataError = nil;
	self.results = [self.insertionContext executeFetchRequest:req error:&dataError];
	if ((dataError != nil) || (results == nil)) {
		
		NSLog(@"Error while fetching\n%@",
			  ([dataError localizedDescription] != nil)
			  ? [dataError localizedDescription] : @"Unknown Error");
	}
	
	if ([self.results count]>0) {
		
		NSMutableArray *ids = [[NSMutableArray alloc]init];
		for(NSManagedObject *item in self.results) {
			
			NSLog(@"Deleted audit: %@", [item valueForKey:@"key"]);
			[ids addObject: [[item valueForKey:@"key"] copy]];
		}
		
		NSLog(@"Deleting: %@", ids);
		
		self.kind = self.pageData.defaultEntityName;
		self.items = ids;		
		
		[self execute];
		ret = YES;
	}
	
	[req release];
	return ret;
}

- (id)init {
	if (self = [super init]) {
		doneNotification = ServerDataDeletedNotification;		
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
	NSLog(@"DeleteService::dealloc");
}

- (void)execute
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* token = [defaults objectForKey:@"UD_TOKEN"];
	
	NSString *data = [items JSONRepresentation];
	if (data) {
		// Construct the request.http://localhost:8080/api/bulk_erase/ParabayOrg-Outlook/Calendar_Appointment?delete=["1"]
		NSString *path = [NSString stringWithFormat: @"/api/bulk_erase/%@/%@", [[Globals sharedInstance] appName], self.kind];
		NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
									data, @"delete",
									token, @"token",
									kClientVersion, kClientVersionKey,
									nil];
		
		[self queueRequest:path withParameters: parameters];
		
	}
	else {
		NSLog(@"Failed to convert to json");
	}	
}

- (void)loadData:(NSDictionary *)json
{		
	NSLog(@"DeleteService::loadData");
	
	if (results) {
		for(NSManagedObject *item in results) {
			[insertionContext deleteObject:item];		
		}
		
		NSError *saveError = nil;
		NSAssert1([insertionContext save:&saveError], @"Unhandled error saving managed object context in delete thread: %@", [saveError localizedDescription]);	
		
		results = nil;
	}
	
	[super loadData:json];	
}

- (NSEntityDescription *)delEntityDescription {
	
    if (delEntityDescription == nil) {
        delEntityDescription = [[NSEntityDescription entityForName: @"ParabayDeletions" inManagedObjectContext:self.insertionContext] retain];
    }
    return delEntityDescription;
}

@end
