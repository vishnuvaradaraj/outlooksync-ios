//
//  LoadLocationService.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-11-24.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LoadLocationService.h"
#import "ParabayAppDelegate.h"
#import "SaveService.h"
#import "Globals.h"
#import "JSON.h"

@implementation LoadLocationService

@synthesize locEntityDescription, offset;

- (id)init {
	if (self = [super init]) {
		doneNotification = ServerLocationSavedNotification;		
		offset = 0;
	}
	return self;
}

- (BOOL) sendLoadRequestWithOffset: (NSUInteger) offsetParam {
	
	self.offset = offsetParam;
	[self execute];
	
	return YES;
}

- (void)execute
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* token = [defaults objectForKey:@"UD_TOKEN"];
			
	// Construct the request.http://localhost:8080/api/locations/ParabayOrg-Outlook
	NSString *path = [NSString stringWithFormat: @"/api/locations/%@", [[Globals sharedInstance] appName]];
	NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								token, @"token",
								nil];
	
	[self queueRequest:path withParameters:parameters];
}

- (void)loadData:(NSDictionary *)json
{			
	
	NSUInteger batchTotal = 0;
	
	NSDictionary *resultSet = [json objectForKey:@"ResultSet"];
	NSArray *results = [resultSet objectForKey:@"Result"];
	NSUInteger count = [[resultSet objectForKey:@"totalResultsAvailable"] integerValue];
		
	for(NSDictionary *result in results) {   
				
		batchTotal++;
		
		NSString *key = [result objectForKey:@"name"];		
		
		NSFetchRequest *req = [[NSFetchRequest alloc] init];
		[req setEntity:self.locEntityDescription];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:
								  @"parabay_id = %@", key];
		[req setPredicate:predicate];
		
		NSError *dataError = nil;
		NSArray *array = [self.insertionContext executeFetchRequest:req error:&dataError];
		if ((dataError != nil) || (array == nil)) {
			NSLog(@"Error while fetching\n%@",
				  ([dataError localizedDescription] != nil)
				  ? [dataError localizedDescription] : @"Unknown Error");
		}
		
		[req release];
		
		NSUInteger isDeleted = [[result objectForKey:@"is_deleted"] integerValue];
		
		NSManagedObject *item = nil;
		if ([array count] > 0) {
			item = [array objectAtIndex:0];
			
			if (isDeleted) {
				NSLog(@"Deleting local item=%@", key);
				[insertionContext deleteObject:item];				
			}
			
		}
		
		if (!isDeleted) {
			
			if (!item) {
				item = [[NSManagedObject alloc] initWithEntity:self.locEntityDescription insertIntoManagedObjectContext:self.insertionContext];
			}
			
			NSString *address = [NSString stringWithFormat:@"%@, %@, %@ %@", [result objectForKey:@"address"], [result objectForKey:@"city"], [result objectForKey:@"state"], [result objectForKey:@"zipcode"]];
			[item setValue:address forKey:@"address"];
			
			NSString *longitude = [result objectForKey:@"longitude"];
			NSNumber *longitudeNumber = [NSNumber numberWithDouble:[longitude doubleValue]];
			[item setValue:longitudeNumber forKey:@"longitude"];
			NSString *latitude = [result objectForKey:@"latitude"];
			NSNumber *latitudeNumber = [NSNumber numberWithDouble:[latitude doubleValue]];
			[item setValue:latitudeNumber forKey:@"latitude"];
			[item setValue:[result objectForKey:@"geohash"] forKey:@"geohash"];
			
			[item setValue:key forKey:@"parabay_id"];
			[item setValue:[NSDate date] forKey:@"parabay_updated"];
			[item setValue:[NSNumber numberWithInt:RecordStatusSynchronized] forKey:@"parabay_status"];
			
		}
				
	}
		
	if (batchTotal > 0) {
		NSError *saveError = nil;
		NSAssert1([insertionContext save:&saveError], @"Unhandled error saving managed object context in import location thread: %@", [saveError localizedDescription]);
	}	
	
	if (self.offset + batchTotal < count) {		
		LoadLocationService *dataLoader = [[[LoadLocationService alloc] init] autorelease];
		dataLoader.privateQueue = self.privateQueue;
		[dataLoader sendLoadRequestWithOffset: self.offset + batchTotal];	
	}
	else {
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithInt:0], @"status", nil];
		[self forwardResult: dict];
	}
	
}

- (NSEntityDescription *)locEntityDescription {
	
    if (locEntityDescription == nil) {
        locEntityDescription = [[NSEntityDescription entityForName: @"ParabayLocations" inManagedObjectContext:self.insertionContext] retain];
    }
    return locEntityDescription;
}

@end
