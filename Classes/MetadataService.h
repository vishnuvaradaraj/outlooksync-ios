//
//  MetadataService.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 19/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseService.h"

@class PageData;
@class MetadataDatabase;

@interface MetadataService : BaseService {

	NSString *databaseName;
	NSArray *rootViews;
	NSArray *dataQueries;
	NSMutableDictionary *pageDataList;
	
}

@property (nonatomic, retain) NSString *databaseName;
@property (nonatomic, retain) NSArray *rootViews;
@property (nonatomic, retain) NSArray *dataQueries;
@property (nonatomic, retain) NSMutableDictionary *pageDataList;

+ (MetadataService*)sharedInstance;
+ (MetadataService*)sharedInstanceWithDatabaseName: (NSString *)dbName;

- (void) clearCache;
- (NSArray *)getRootViews;
- (PageData *)getPageData: (NSString *)name forEditorPage: (NSString *)editorName;
- (NSDictionary *)getPageMetadata: (NSString *)name;
- (NSDictionary *)getDataQuery: (NSString *)name;
- (NSMutableArray *)getDataQueries;

@end
