//
//  BaseService.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 18/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Globals.h"
#import "BaseService.h"
#import "MetadataService.h"
#import "GTMNSDictionary+URLArguments.h"
#import "JSON.h"
#import "PageData.h"
#import "ParabayAppDelegate.h"

static ASINetworkQueue *sharedQueue;

@implementation BaseService

@synthesize host, doneNotification, serviceDelegate;
@synthesize persistentStoreCoordinator, entityDescription;
@synthesize pageData, insertionContext, pageName, privateQueue;

+ (ASINetworkQueue*) sharedQueue {
	
	if (!sharedQueue) {
        sharedQueue = [[ASINetworkQueue alloc] init]; 
		[sharedQueue setMaxConcurrentOperationCount:1];
		[sharedQueue setShouldCancelAllRequestsOnFailure:NO];
		[sharedQueue go];
	}
	
    return sharedQueue;
}

- (id)init
{
	if (self = [super initWithURL:[NSURL URLWithString: @""]]) {
		host = DEFAULT_HOST_ADDRESS;	
		delegate = self;
	}
	return self;
}

- (void)sendRequest: (NSString *)path withParameters: (NSDictionary *)parameters {
	
	NSString *serviceUrl = [host stringByAppendingFormat:@"%@", path];
	
	NSLog(@"Sending request: %@", serviceUrl);
	[self setURL:[NSURL URLWithString:serviceUrl]];
	
	for (NSString *key in parameters) {
		[self setPostValue:[parameters objectForKey:key] forKey:key];
	}
	
	// Dispatch the request.
	[self start];
	[self requestFinished: self];
}

- (void)queueRequest: (NSString *)path withParameters: (NSDictionary *)parameters {
	
	NSString *serviceUrl = [host stringByAppendingFormat:@"%@", path];
	
	NSLog(@"Sending request: %@?%@", serviceUrl, [parameters gtm_httpArgumentsString]);
	[self setURL:[NSURL URLWithString:serviceUrl]];
	
	for (NSString *key in parameters) {
		[self setPostValue:[parameters objectForKey:key] forKey:key];
	}
	
	// Dispatch the request.
	[self.privateQueue addOperation:self];
}

/* overload this */
- (void)execute
{
	
}

/* overload this */
- (void)loadData:(NSDictionary *)json
{			
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInt:0], @"status", nil];
	[self forwardResult: dict];
}

- (void)requestFinished:(ASIHTTPRequest *)requestParam
{
	NSString *responseBody = [requestParam responseString];
	//NSLog(@"Response=%@", responseBody);
	
    NSDictionary *json = [responseBody JSONValue];    
	
	if (json) {
		
		NSUInteger status = [[json objectForKey:@"status"] integerValue];		
		if (0 == status) {
			
			if (delegate && [delegate respondsToSelector:@selector(serviceDidSave:)]) {
				[[NSNotificationCenter defaultCenter] addObserver:delegate selector:@selector(serviceDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.insertionContext];
			}	
			
			[self loadData:json];
			//cancel save notifications
			if (delegate && [delegate respondsToSelector:@selector(serviceDidSave:)]) {
				[[NSNotificationCenter defaultCenter] removeObserver:delegate name:NSManagedObjectContextDidSaveNotification object:self.insertionContext];
			}			
		}
		else {		
					
			if (5 == status) {
				//access denied
				NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];	
				[defaults removeObjectForKey:@"UD_TOKEN"];				
			}
			
			NSString *errorMessage = [json objectForKey:@"error_message"];
			if (!errorMessage) {
				errorMessage = [NSString stringWithFormat: @"Server error: %d", status];
			}
			
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithInt:status], @"status", [errorMessage copy], NSLocalizedDescriptionKey, nil];	
			[self forwardResult: dict];
		}
	}
}

- (void)requestFailed:(ASIHTTPRequest *)requestParam
{
	NSLog(@"Error: request failed: %@", [[requestParam error] localizedDescription]);
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:-1], @"status", nil];			
	[self forwardResult: dict];
}

- (void)forwardResultHelper:(NSDictionary *)result {
	
	[[NSNotificationCenter defaultCenter] postNotificationName:doneNotification object:nil userInfo:result];

    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(service:withResult:)]) {
        [self.delegate service:self withResult: result];
    }
}

- (void)forwardResult: (NSDictionary *)result {
		
	if ([NSThread isMainThread]) {
		[self forwardResultHelper:result];
	}
	else {
		[self performSelectorOnMainThread:@selector(forwardResultHelper:) withObject:result waitUntilDone:NO];
	}
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

- (NSManagedObjectContext *)insertionContext {
	
    if (insertionContext == nil) {
        insertionContext = [[NSManagedObjectContext alloc] init];
        [insertionContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    }
    return insertionContext;
}

- (NSEntityDescription *)entityDescription {
	
	if (entityDescription == nil && self.pageData) {
		entityDescription = [[NSEntityDescription entityForName: self.pageData.defaultEntityName inManagedObjectContext:self.insertionContext] retain];
	}
	return entityDescription;
}

- (PageData *)pageData {
	
	if (pageData == nil && self.pageName) {
		pageData = [[MetadataService sharedInstance] getPageData:pageName forEditorPage:nil ];
	}
	return pageData;
}
	
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {

	if (persistentStoreCoordinator == nil) {
		ParabayAppDelegate *appDelegate = (ParabayAppDelegate *)[[UIApplication sharedApplication] delegate];
		persistentStoreCoordinator = appDelegate.persistentStoreCoordinator;
	}
	
	return persistentStoreCoordinator;
}

- (ASINetworkQueue *)privateQueue {
	
	if (privateQueue == nil) {
		privateQueue = [BaseService sharedQueue];
	}
	return privateQueue;
}

@end
