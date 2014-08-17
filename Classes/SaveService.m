//
//  SaveService.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 06/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ParabayAppDelegate.h"
#import "SaveService.h"
#import "Globals.h"
#import "JSON.h"
#import "PageData.h"

@implementation SaveService

@synthesize items, kind, results;

- (BOOL)sendSaveRequest: (NSString *)pageNameParam {
	
	BOOL ret = NO;
	
	NSLog(@"Checking for updates: %@", pageNameParam);	
	self.pageName = pageNameParam;
			
	NSFetchRequest *req = [[NSFetchRequest alloc] init];
	[req setEntity:self.entityDescription];
	[req setFetchLimit:10];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"parabay_status = %d", RecordStatusUpdated];
	[req setPredicate:predicate];
	
	NSError *dataError = nil;
	self.results = [self.insertionContext executeFetchRequest:req error:&dataError];
	if ((dataError != nil) || (self.results == nil)) {
		NSLog(@"Error while fetching\n%@",
			  ([dataError localizedDescription] != nil)
			  ? [dataError localizedDescription] : @"Unknown Error");
	}
	
	if ([self.results count]>0) {
		
		NSLog(@"Found updates: %@ = %d", self.pageName, [results count]);
		
		NSMutableArray *itemsList = [[[NSMutableArray alloc] init] autorelease];
		for (NSManagedObject *item in self.results) {
			[itemsList addObject: [self convertNSManagedObjectToDictionary:item]];
		}
		
		NSLog(@"Items List=%@", itemsList);
		self.kind = self.pageData.defaultEntityName;
		self.items = itemsList;
		
		[self execute];
		ret = YES;
	}
	
	[req release];
	return ret;
}

- (id)init {
	
	if (self = [super init]) {
		doneNotification = ServerDataSavedNotification;		
	}
	return self;
}

- (void)execute
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* token = [defaults objectForKey:@"UD_TOKEN"];
	
	//NSLog(@"Saving items=%@", self.items);
	
	NSString *data = [items JSONRepresentation];
	
	if (data && token) {
		
		// Construct the request.http://localhost:8080/api/savearray/ParabayOrg-Outlook/Calendar_Appointment?data=[{"MeetingOrganizer":%20"Varadaraj,%20Vishnu2",%20"Subject":%20"Subaru%20Forrester%20appt2."}]
		NSString *path = [NSString stringWithFormat: @"/api/savearray/%@/%@", [[Globals sharedInstance] appName], self.kind];
		NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
									data, @"data",
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
	if (results) {
		for(NSManagedObject *item in results) {
			[item setValue:[NSNumber numberWithInt:RecordStatusSynchronized] forKey: @"parabay_status"];
		}
		
		NSError *saveError = nil;
		NSAssert1([insertionContext save:&saveError], @"Unhandled error saving managed object context in saver thread: %@", [saveError localizedDescription]);	
		
		results = nil;
	}	
	
	[super loadData:json];	
}


@end
