//
//  SaveFileService.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-12-06.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SaveFileService.h"
#import "ParabayAppDelegate.h"
#import "SaveService.h"
#import "Globals.h"
#import "JSON.h"

@implementation SaveFileService

@synthesize item, imgEntityDescription;

- (BOOL)sendSaveRequest {
	
	BOOL ret = NO;
	
	NSFetchRequest *req = [[NSFetchRequest alloc] init];
	[req setEntity:self.imgEntityDescription];
	[req setFetchLimit:1];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"parabay_status = %d", RecordStatusUpdated];
	[req setPredicate:predicate];
	
	NSError *dataError = nil;
	NSArray *results = [self.insertionContext executeFetchRequest:req error:&dataError];
	if ((dataError != nil) || (results == nil)) {
		NSLog(@"Error while fetching\n%@",
			  ([dataError localizedDescription] != nil)
			  ? [dataError localizedDescription] : @"Unknown Error");
	}
	
	if ([results count]>0) {
		
		NSLog(@"Found file updates: %d", [results count]);
		item = [results objectAtIndex:0];
		
		[self execute];
		ret = YES;
	}
	else {
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithInt:0], @"status", nil];
		[self forwardResult: dict];
	}
	
	[req release];
	return ret;
}

- (id)init {
	
	if (self = [super init]) {
		doneNotification = ServerFileSavedNotification;		
	}
	return self;
}

- (void)execute
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* token = [defaults objectForKey:@"UD_TOKEN"];
			
	if (item && token) {
		
		// Construct the request.http://localhost:8080/api/savearray/ParabayOrg-Outlook/Calendar_Appointment?data=[{"MeetingOrganizer":%20"Varadaraj,%20Vishnu2",%20"Subject":%20"Subaru%20Forrester%20appt2."}]
		NSString *path = @"/assets"; 
		NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
									token, @"token",
									[item valueForKey:@"parabay_id"], @"id",
									kClientVersion, kClientVersionKey,
									nil];
		
		[self setFile:[item valueForKey:@"cacheFilePath"] forKey:@"upload"];		
		[self queueRequest:path withParameters: parameters];
	}
	else {
		NSLog(@"Failed to convert to json");
	}
}

- (void)loadData:(NSDictionary *)json
{		
	if (item) {
		[item setValue:[NSNumber numberWithInt:RecordStatusSynchronized] forKey: @"parabay_status"];
		
		NSError *saveError = nil;
		NSAssert1([insertionContext save:&saveError], @"Unhandled error saving managed object context in saver thread: %@", [saveError localizedDescription]);	
		
		item = nil;
	}	
	
	/*
	SaveFileService *dataLoader = [[[SaveFileService alloc] init] autorelease];
	dataLoader.privateQueue = self.privateQueue;
	[dataLoader sendSaveRequest];	
	*/
}

- (NSEntityDescription *)imgEntityDescription {
	
    if (imgEntityDescription == nil) {
        imgEntityDescription = [[NSEntityDescription entityForName: @"ParabayImages" inManagedObjectContext:self.insertionContext] retain];
    }
    return imgEntityDescription;
}

@end
