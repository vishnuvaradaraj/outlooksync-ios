//
//  LoadPageMetadata.m
//  LoginApp
//
//  Created by Vishnu Varadaraj on 16/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LoadPageMetadata.h"
#import "LoadDataQuery.h"
#import "Globals.h"
#import "JSON.h"

@implementation LoadPageMetadata

@synthesize stopLoading;

- (id)init {
	if (self = [super init]) {
		stopLoading = NO;
	}
	return self;
}

- (void)loadData:(NSDictionary *)json
{	
	if (!stopLoading) {
		NSDictionary *pageMetadata = [[json objectForKey:@"page_metadata"] copy];	
		NSArray *resultsTemp = [[pageMetadata objectForKey:@"data_queries"] copy];	
		
		for(NSDictionary *result in resultsTemp) {   
			
			NSString *dataQuery = [result objectForKey:@"name"];
			
			LoadDataQuery *loadDataQuery = (LoadDataQuery *) [[ [LoadDataQuery alloc] init ] autorelease];	
			[subLoaders addObject:loadDataQuery];
			loadDataQuery.name = [NSString stringWithFormat:@"/api/dataquery_metadata/%@/%@", [[Globals sharedInstance] appName], dataQuery];
			[loadDataQuery execute];	
			
		}
		[resultsTemp release];
		[pageMetadata release];
	}
}

@end
