//
//  LoadRootViewMaps.m
//  LoginApp
//
//  Created by Vishnu Varadaraj on 16/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LoadRootViewMaps.h"
#import "LoadPageMetadata.h"
#import "Globals.h"
#import "JSON.h"

@implementation LoadRootViewMaps

- (void)loadData:(NSDictionary *)json
{
	
	NSArray *resultsTemp = [[json objectForKey:@"data"] copy];	
	[BaseLoadMetadataService setTotalRequests:[resultsTemp count] * 3];
	for(NSDictionary *result in resultsTemp) {   
		
		NSString *viewMap = [result objectForKey:@"name"];
		
		LoadPageMetadata *loadListMetadata = (LoadPageMetadata *) [[ [LoadPageMetadata alloc] init ] autorelease];	
		[subLoaders addObject:loadListMetadata];
		loadListMetadata.name = [NSString stringWithFormat:@"/api/page_metadata/%@/%@", [[Globals sharedInstance] appName], viewMap]; 
		[loadListMetadata execute];	
		
		LoadPageMetadata *loadEditorMetadata = (LoadPageMetadata *) [[ [LoadPageMetadata alloc] init ] autorelease];	
		loadEditorMetadata.stopLoading = YES;
		[subLoaders addObject:loadEditorMetadata];
		loadEditorMetadata.name = [NSString stringWithFormat:@"/api/page_metadata/%@/%@", [[Globals sharedInstance] appName], [viewMap substringToIndex:([viewMap length]-1) ]];
		[loadEditorMetadata execute];	
		
	}
	[resultsTemp release];
}

@end
