//
//  MetadataService.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 19/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MetadataService.h"
#import "MetadataDatabase.h"
#import "MetadataCache.h"
#import "EntitySchema.h"
#import "PageData.h"
#import "Globals.h"
#import "JSON.h"

static MetadataService* SharedInstance;

@implementation MetadataService

@synthesize rootViews, dataQueries, pageDataList, databaseName;


+ (MetadataService*)sharedInstance {
	return [MetadataService sharedInstanceWithDatabaseName: [EntitySchema metaDatabaseNameForVersion:kCurrentSchemaVersion] ];
}

+ (MetadataService*)sharedInstanceWithDatabaseName: (NSString *)dbName {
	
	if (!SharedInstance || NSOrderedSame != [SharedInstance.databaseName compare:dbName]) {
        SharedInstance = [[MetadataService alloc] init]; 
		SharedInstance.databaseName = [dbName copy];	
	}
	
    return SharedInstance;
}

- (id)init {
	if (self = [super init]) {
		self.pageDataList = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (NSArray *)getRootViews {
	
	if (!self.rootViews) {
		MetadataCache *entry = [[MetadataDatabase sharedInstanceWithDatabaseName:databaseName] fetchCacheEntry: [NSString stringWithFormat: @"/api/root_view_maps/%@", [[Globals sharedInstance] appName]]];
		if (entry) {
			NSDictionary *json = [[entry valueForKey:@"value"] JSONValue];  
			self.rootViews = [json objectForKey:@"data"];	
		}
	}
	
	return self.rootViews;
}

- (PageData *)getPageData: (NSString *)name forEditorPage: (NSString *)editorName {
		
	@synchronized(self) {

		PageData *data = nil;
		
		if (name && !editorName) {
			editorName = [name substringToIndex:([name length]-1) ];
		}
		else if (!name && editorName) {
			name = [NSString stringWithFormat:@"%@s", editorName];
		}
		
		data = [self.pageDataList objectForKey:name];
		if (!data) {
			
			data = [[PageData alloc] init];
			data.pageName = [name copy];
			data.editorPageName = [editorName copy];		
			
			[data loadPageData];
			
			NSLog(@"Creating pageData=(%@, %@)", data.pageName, data.editorPageName);
			
			[self.pageDataList setObject:data forKey:data.pageName];
		}
		return data;
	}
	
	NSLog(@"Error: Unexpected exit from getPageData");
	return nil;
}

- (NSDictionary *)getPageMetadata: (NSString *)name {
	
	NSDictionary *pageMetadata = nil;
	
	NSString *key =  [NSString stringWithFormat:@"/api/page_metadata/%@/%@", [[Globals sharedInstance] appName], name];
	MetadataCache *entry = [[MetadataDatabase sharedInstanceWithDatabaseName:databaseName] fetchCacheEntry: key];
	if (entry) {
		NSDictionary *json = [entry.value JSONValue];    
		pageMetadata = [[json objectForKey:@"page_metadata"] copy];				
	}
	
	return pageMetadata;
}

- (NSDictionary *)getDataQuery: (NSString *)name {
	
	NSDictionary *dataQuery = nil;
	
	NSString *key =  [NSString stringWithFormat:@"/api/dataquery_metadata/%@/%@", [[Globals sharedInstance] appName], name];
	MetadataCache *entry = [[MetadataDatabase sharedInstanceWithDatabaseName:databaseName] fetchCacheEntry: key];
	if (entry) {
		NSDictionary *json = [entry.value JSONValue];    
		dataQuery = [[json objectForKey:@"dataquery_metadata"] copy];				
	}
	
	return dataQuery;
}

- (NSMutableArray *)getDataQueries {
	
	return [[MetadataDatabase sharedInstanceWithDatabaseName:databaseName] fetchDataQueries];
}

- (void) clearCache {
	self.rootViews = nil;
	self.dataQueries = nil;
	[self.pageDataList removeAllObjects];
}

- (void)dealloc {
	
	[self clearCache];
	[self.pageDataList dealloc];
	[super dealloc];
}


@end
