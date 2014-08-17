//
//  EntityLoader.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 19/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EntityLoader.h"
#import "Globals.h"
#import "JSON.h"
#import "MetadataService.h"
#import "ParabayAppDelegate.h"
#import "Reachability.h"
#import "PageData.h"

@interface EntityLoader ()

@property BOOL done;
@property NSUInteger countForCurrentBatch;
// The autorelease pool property is assign because autorelease pools cannot be retained.
@property (nonatomic, assign) NSAutoreleasePool *importPool;

@end

@implementation EntityLoader

@synthesize dataURL, delegate, persistentStoreCoordinator, entityDescription;
@synthesize done, countForCurrentBatch, importPool, pageData;
@synthesize host, doneNotification, insertionContext, pageName, offset;

- (id)init {
	if (self = [super init]) {
		host = DEFAULT_HOST_ADDRESS;	
		offset = 0;
		doneNotification = DataListLoadedNotification;
	}
	return self;
}

- (void)dealloc {
    TT_RELEASE_SAFELY(dataURL);
    TT_RELEASE_SAFELY(persistentStoreCoordinator);
    TT_RELEASE_SAFELY(insertionContext);
    [super dealloc];
}

- (NSString *) queryToSynch: (NSString *)queryString {
	
	NSDictionary *json = [queryString JSONValue]; 
	[json setValue:[NSNumber numberWithBool:YES ] forKey:@"include_deleted_items"];
		
	NSString *ret = [json JSONRepresentation];
	NSLog(@"Query=%@", ret);

	return ret;
}

- (void)sendRequest {

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* token = [defaults objectForKey:@"UD_TOKEN"];
		
	if (token) {
		
		// Construct the request.  (q['include_deleted_items'])
		NSDictionary *dataQueryObject = [pageData.dataQuery objectForKey:@"data_query"];
		NSString *query = [self queryToSynch: [dataQueryObject objectForKey:@"query"]];
		
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat: @"dd/MM/yyyy"]; 
		NSString *today = [formatter stringFromDate: [NSDate date]];	
		
		NSString *path = [NSString stringWithFormat: @"/api/list/%@", kParabayApp];
		NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
									[query stringByReplacingOccurrencesOfString:@"@@today@@" withString:today], @"query",
									token, @"token",
									[NSString stringWithFormat:@"%lu", (unsigned long)offset], @"offset",
									kClientVersion, kClientVersionKey,
									nil];
		
		NSString *url = [host stringByAppendingFormat:@"%@", path];
		NSLog(@"Fetching data: %@", url);
		
		TTURLRequest *request = [TTURLRequest requestWithURL:url delegate:self];
		[request.parameters addEntriesFromDictionary:parameters];
		request.cachePolicy = TTURLRequestCachePolicyNone;
		request.response = self;
		request.httpMethod = @"POST";
		
		// Dispatch the request.
		[request send];
	}
	
}

- (void)loadData:(NSDictionary *)json {
	
	NSUInteger batchTotal = 0;
				
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat: @"yyyy-MM-dd'T'HH:mm"]; // 2009-02-01 19:50:41 PST		
	
	NSArray *results = [json objectForKey:@"data"];
	NSUInteger count = [[json objectForKey:@"count"] integerValue];
		
	self.importPool = [[NSAutoreleasePool alloc] init];
	
	for(NSDictionary *result in results) {   
	
		batchTotal++;
		
		NSString *key = [result objectForKey:@"id"];		
		//NSLog(@"Server data(%d): %@", batchTotal, [result valueForKey:@"Subject"]);
		
		NSFetchRequest *req = [[NSFetchRequest alloc] init];
		[req setEntity:self.entityDescription];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:
								  @"name = %@", key];
		[req setPredicate:predicate];
		
		NSError *error = nil;
		NSArray *array = [self.insertionContext executeFetchRequest:req error:&error];
		if ((error != nil) || (array == nil)) {
			NSLog(@"Error while fetching\n%@",
				  ([error localizedDescription] != nil)
				  ? [error localizedDescription] : @"Unknown Error");
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
						
			for(NSString *propertyName in pageData.defaultEntityProperties) {
				
				NSDictionary *entityPropertyMetadata = [pageData.defaultEntityProperties objectForKey:propertyName];
				
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
		
		if (countForCurrentBatch == 30) {
			NSError *saveError = nil;
			NSAssert1([insertionContext save:&saveError], @"Unhandled error saving managed object context in import thread: %@", [saveError localizedDescription]);
			countForCurrentBatch = 0;
			
			TT_RELEASE_SAFELY(self.importPool);
			self.importPool = [[NSAutoreleasePool alloc] init];			
		}
		
	}
			
	if (self.offset + batchTotal < count) {		
		ParabayAppDelegate *appDelegate = (ParabayAppDelegate *) [[UIApplication sharedApplication] delegate];	
		[appDelegate queueImportForPage:self.pageName withOffset: self.offset+batchTotal];
	}
	else {
		NSString *key = [NSString stringWithFormat:kLastStoreUpdateKey, self.pageName];
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:key];
		
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  self.pageName, @"pageName", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName: DataListLoadedNotification object:nil userInfo:dict];
		
	}
	
	[formatter release];
}

- (void)main {
	
	NSAutoreleasePool *threadImportPool = [[NSAutoreleasePool alloc] init];	
	
    if (delegate && [delegate respondsToSelector:@selector(importerDidSave:)]) {
        [[NSNotificationCenter defaultCenter] addObserver:delegate selector:@selector(importerDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.insertionContext];
    }
	
    done = NO;
	
	NSLog(@"Start EntityLoader %@: offset=%d", self.pageName, self.offset);	
	pageData = [[MetadataService sharedInstance] getPageData:pageName forEditorPage:nil ];

	[self sendRequest];
		
	do {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	} while (!done);
		
    NSError *saveError = nil;
    NSAssert1([insertionContext save:&saveError], @"Unhandled error saving managed object context in import thread: %@", [saveError localizedDescription]);
	
    if (delegate && [delegate respondsToSelector:@selector(importerDidSave:)]) {
        [[NSNotificationCenter defaultCenter] removeObserver:delegate name:NSManagedObjectContextDidSaveNotification object:self.insertionContext];
    }
	
	TT_RELEASE_SAFELY(self.importPool);
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

#pragma mark TTURLRequestDelegate

- (NSError*)request:(TTURLRequest*)request processResponse:(NSHTTPURLResponse*)response
			   data:(id)data
{
    NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *json = [responseBody JSONValue];    
	
	NSUInteger status = [[json objectForKey:@"status"] integerValue];		
	if (0 == status) {
		
		[self loadData:json];	

	}
	else {		
		NSString *errorMessage = [json objectForKey:@"error_message"];
		if (!errorMessage) {
			errorMessage = [NSString stringWithFormat: @"Server error: %d", status];
		}
		
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithInt:status], @"status", [errorMessage copy], NSLocalizedDescriptionKey, nil];	
		return [NSError errorWithDomain:PARABAY_ERROR_DOMAIN code:PB_EC_INVALID_STATUS
							   userInfo:dict];
	}
	
    [responseBody release];
	
	// Set the condition which ends the run loop.
	done = YES;
	
	return nil;
}

- (void)request:(TTURLRequest*)request didFailLoadWithError:(NSError*)error 
{	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  self.pageName, @"pageName", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: DataListLoadedNotification object:nil userInfo:dict];
	
	[self performSelectorOnMainThread:@selector(forwardError:) withObject:error waitUntilDone:NO];
	// Set the condition which ends the run loop.
	done = YES;

}

- (void)requestDidCancelLoad:(TTURLRequest*)request 
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  self.pageName, @"pageName", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: DataListLoadedNotification object:nil userInfo:dict];
	
	[self performSelectorOnMainThread:@selector(forwardCancel:) withObject:[NSString stringWithFormat:@"Cancelled", 32] waitUntilDone:NO];
	// Set the condition which ends the run loop.
	done = YES;
}

- (void)forwardError:(NSError *)error {
	
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(importer:didFailWithError:)]) {
        [self.delegate importer:self didFailWithError:error];
    }
}

- (void)forwardCancel:(NSString *)status {
	
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(importer:cancelledRequest:)]) {
        [self.delegate importer:self cancelledRequest:status];
    }
}

@end
