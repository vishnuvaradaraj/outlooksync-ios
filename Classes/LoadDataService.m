//
//  LoadDataService.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-11-27.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LoadDataService.h"
#import "ParabayAppDelegate.h"
#import "RelatedEntityLinker.h"
#import "Globals.h"
#import "JSON.h"
#import "PageData.h"
#import "SyncService.h"

@implementation LoadDataService

@synthesize offset, relatedPropertyLinker;

- (id)init {
	if (self = [super init]) {
		doneNotification = DataListLoadedNotification;	
		relatedPropertyLinker = [[RelatedEntityLinker alloc] init];
		offset = 0;
	}
	return self;
}

- (void)dealloc {
	TT_RELEASE_SAFELY(relatedPropertyLinker);
	[super dealloc];
}

- (BOOL) sendLoadRequest: (NSString *)page withOffset: (NSUInteger) offsetParam {
	
	self.pageName = page;
	self.offset = offsetParam;
	
	[self execute];
	
	return YES;
}

/*
 http://parabaydata.appspot.com/api/list/ParabayOrg-Outlook?client_version=1.0&offset=10&query={"kind":"Calendar_Appointment","include_deleted_items":true,"orders":[],"columns":[],
 "filters":[{"condition":"updated >=","param":"2009-12-10T02:24:44.710102","type":"timestamp"}]}
 */
- (void)execute {
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* token = [defaults objectForKey:@"UD_TOKEN"];
	
	if (token) {
	
		NSLog(@"Start EntityLoader %@: offset=%d", self.pageName, self.offset);	
		
		NSDictionary *dataQueryObject = [self.pageData.dataQuery objectForKey:@"data_query"];
		NSString *query = [self queryToSynch: dataQueryObject];
		
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat: @"dd/MM/yyyy"]; 
		NSString *today = [formatter stringFromDate: [NSDate date]];	
		
		NSString *path = [NSString stringWithFormat: @"/api/list/%@", [[Globals sharedInstance] appName]];
		NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
									[query stringByReplacingOccurrencesOfString:@"@@today@@" withString:today], @"query",
									token, @"token",
									[NSString stringWithFormat:@"%lu", (unsigned long)offset], @"offset",
									kClientVersion, kClientVersionKey,
									nil];
		[self queueRequest:path withParameters: parameters];
	}
}

- (void)loadData:(NSDictionary *)json
{			
	NSUInteger batchTotal = 0; //total read so far
	NSUInteger countForCurrentBatch = 0; //current total, reset after save
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat: @"yyyy-MM-dd'T'HH:mm"]; // 2009-02-01 19:50:41 PST		
	
	NSArray *results = [json objectForKey:@"data"];
	NSUInteger count = [[json objectForKey:@"count"] integerValue];
		
	for(NSDictionary *result in results) {   
		
		batchTotal++;
		
		NSString *key = [result objectForKey:@"id"];		
		//NSLog(@"Server data(%d): %@", batchTotal, [result valueForKey:@"Subject"]);
		
		NSFetchRequest *req = [[NSFetchRequest alloc] init];
		[req setEntity:self.entityDescription];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:
								  @"name = %@", key];
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
			//NSLog(@"Found existing item: %@", [item valueForKey:@"Subject"]);
			
			if (isDeleted) {
				NSLog(@"Deleting local item=%@", key);
				[insertionContext deleteObject:item];				
			}
			
		}
		
		if (!isDeleted) {
			
			if (!item) {
				item = [[NSManagedObject alloc] initWithEntity:self.entityDescription insertIntoManagedObjectContext:self.insertionContext];
			}
			
			for(NSString *propertyName in self.pageData.defaultEntityProperties) {
				
				NSDictionary *entityPropertyMetadata = [self.pageData.defaultEntityProperties objectForKey:propertyName];
				
				NSString *propertyValue = [result objectForKey:propertyName];
				//special handling for name property
				if (NSOrderedSame == [propertyName compare:@"name"]) {
					propertyValue = key;
				}
				
				@try {
					
					NSString *dataType = [entityPropertyMetadata objectForKey:@"type_info"];				
					if (propertyValue) {				
						if (NSOrderedSame == [dataType compare:@"date"] || NSOrderedSame == [dataType compare:@"time"]) {
							NSDate *value = [formatter dateFromString:propertyValue];
							[item setValue: value  forKey: propertyName];
						}
						else if (NSOrderedSame == [dataType compare:@"boolean"]) {
							NSNumber *value = [NSNumber numberWithBool:NO];
							[item setValue: value  forKey: propertyName];
						}
						else if (NSOrderedSame == [dataType compare:@"integer"]) {
							NSNumber *value = [NSNumber numberWithInt:0];
							[item setValue: value  forKey: propertyName];
						}
						else if (NSOrderedSame == [dataType compare:@"float"]) {
							NSNumber *value = [NSNumber numberWithFloat:0.0];
							[item setValue: value  forKey: propertyName];
						}
						else if (NSOrderedSame == [dataType compare:@"image"]) {

							relatedPropertyLinker.insertionContext = self.insertionContext;
							[relatedPropertyLinker link:item imageField:propertyName forId:propertyValue];

						}
						else if (NSOrderedSame == [dataType compare:@"location"]) {
							
							relatedPropertyLinker.insertionContext = self.insertionContext;
							[relatedPropertyLinker link:item locationField:propertyName forId:propertyValue];
													}
						else {		
							//NSLog(@"Property(%@):%@", propertyName, dataType);
							if ((NSNull *)propertyValue != [NSNull null]) {
								[item setValue:[propertyValue description] forKey:propertyName];
							}
							else {
								NSLog(@"%@ is NULL", propertyName);
							}
							
						}
					}
				}
				@catch (NSException *exception) {
					NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
				}
				
			}
			
			[item setValue:key forKey:@"parabay_id"];
			[item setValue:[NSDate date] forKey:@"parabay_updated"];
			[item setValue:[NSNumber numberWithInt:RecordStatusSynchronized] forKey:@"parabay_status"];
			
			//NSLog(@"Saving: %@ === %@", item, result);
		}
		
		countForCurrentBatch++;
		
		if (countForCurrentBatch >= 10) {
			NSError *saveError = nil;
			NSAssert1([insertionContext save:&saveError], @"Unhandled error saving managed object context in import thread: %@", [saveError localizedDescription]);
			countForCurrentBatch = 0;			
		}
		
	}
	
	NSLog(@"Loaded data rows: %d", batchTotal);
	
	//save data if necessary.
	if (countForCurrentBatch > 0) {
		NSError *saveError = nil;
		NSAssert1([insertionContext save:&saveError], @"Unhandled error saving managed object context in import thread: %@", [saveError localizedDescription]);
	}
			
	//fetch more data if necessary
	if (self.offset + batchTotal < count) {	
		
		LoadDataService *dataLoader = [[[LoadDataService alloc] init] autorelease];
		dataLoader.privateQueue = self.privateQueue;
		[dataLoader sendLoadRequest:self.pageName withOffset: self.offset + batchTotal];
	}
	else {
		
		NSString *key = [NSString stringWithFormat:kLastStoreUpdateKey, self.pageName];
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:key];
		
		NSString *serverSyncToken = [json objectForKey:@"sync_token"];
		[[SyncService sharedInstance] updateServerToken:serverSyncToken forKind: [self.pageData defaultEntityName]];
		
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  self.pageName, @"pageName", nil];
		[self forwardResult:dict];		
	}
	
	[formatter release];	
}

- (NSString *) queryToSynch: (NSDictionary *)dataQueryObject {
	
	NSString *serverSyncToken = nil;

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL fullResync = [defaults boolForKey:@"slow_sync_preference"];	
	if (!fullResync) {
		serverSyncToken = [[SyncService sharedInstance] fetchServerTokenForKind:[self.pageData defaultEntityName]];					
	}

	NSString *queryString = [dataQueryObject objectForKey:@"query"];	
	if (serverSyncToken) {
		
		NSString *syncQuery = [dataQueryObject objectForKey:@"syncQuery"];
		if (!syncQuery || [syncQuery length]==0) {
			syncQuery = @"{\"columns\":[],\"kind\":\"%@\",\"filters\":[{\"condition\":\"updated >=\",\"param\":\"%@\",\"type\":\"timestamp\"}],\"orders\":[]}";
		}
		
		queryString = [NSString stringWithFormat: syncQuery, [self.pageData defaultEntityName],  serverSyncToken];
	}
	
	NSDictionary *json = [queryString JSONValue]; 
	[json setValue:[NSNumber numberWithBool:YES ] forKey:@"include_deleted_items"];
	
	NSString *ret = [json JSONRepresentation];
	NSLog(@"Query=%@", ret);
	
	return ret;
}

@end
