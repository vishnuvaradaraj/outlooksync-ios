//
//  BaseLoadMetadataService.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 18/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BaseLoadMetadataService.h"
#import "GTMNSDictionary+URLArguments.h"
#import "JSON.h"
#import "Globals.h"
#import "LoadRootViewMaps.h"

static NSInteger pendingRequests;
static NSInteger totalRequests;
static LoadRootViewMaps *loadViewMaps;
static id <LoadMetadataDelegate> delegate;

@implementation BaseLoadMetadataService

@synthesize name, subLoaders;

+ (void) setTotalRequests: (NSUInteger) totalReq {
	totalRequests = totalReq;
}

+ (void)loadAll {
	
	[BaseLoadMetadataService loadAllWithDelegate: nil];

}

+ (void)loadAllWithDelegate: (id<LoadMetadataDelegate>) callback {
	
	totalRequests = TOTAL_METADATA_REQUESTS;
	pendingRequests = 0;
	if (!loadViewMaps) {	
		delegate = callback;
		loadViewMaps = (LoadRootViewMaps *) [ [LoadRootViewMaps alloc] init ];		
		loadViewMaps.name = [NSString stringWithFormat: @"/api/root_view_maps/%@", [[Globals sharedInstance] appName]]; 
		[loadViewMaps execute];		
	} else {
		TTLOG(@"Error: Previous load metadata is still in progress.");
	}	
}

+(void)metadataItemLoaded: (NSNotification *)aNotification {
	pendingRequests--;
	
	NSLog(@"Pending requests=%d (-1)", pendingRequests);
	if (delegate != nil && [delegate respondsToSelector:@selector(progressPending:withTotal:)]) {
        [delegate progressPending:pendingRequests withTotal:totalRequests];
    }
	
	if (0 == pendingRequests) {
		delegate = nil;
		[loadViewMaps release];
		loadViewMaps = nil;
	}
}

+ (void) initialize {
	
	if ([self class] == [BaseLoadMetadataService class]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(metadataItemLoaded:) name:SubMetadataLoadedNotification object:nil];	
	}
}

- (id)init {
	if (self = [super init]) {
		doneNotification = SubMetadataLoadedNotification;	
		subLoaders = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)loadData:(NSDictionary *)json {

}

- (void)execute {
    // Construct the request.
	
	pendingRequests++;
	NSLog(@"Pending requests=%d (+1)", pendingRequests);
	if (delegate != nil && [delegate respondsToSelector:@selector(progressPending:withTotal:)]) {
        [delegate progressPending:pendingRequests withTotal:totalRequests];
    }
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];	
	NSString* token = [defaults objectForKey:@"UD_TOKEN"];
	
	NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								token, @"token",
								nil];
	
	[self queueRequest:name withParameters: parameters];
}


- (void)dealloc {
	
	TTLOG(@"LoadMetadata dealloc");
	
	[subLoaders release];
	[super dealloc];
}

@end
