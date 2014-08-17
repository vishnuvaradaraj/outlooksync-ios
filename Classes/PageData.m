//
//  PageData.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-10-04.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PageData.h"
#import "MetadataService.h"
#import "JSON.h"

@implementation PageData

@synthesize pageName, editorPageName, listPageMetadata, editorPageMetadata, listLayoutStr, editorLayoutStr, listLayout, editorLayout, defaultEntityName, dataQuery, defaultEntityMetadata, defaultEntityProperties;

-(void) loadPageData {
	
	listPageMetadata = [[MetadataService sharedInstance] getPageMetadata: pageName];	
	NSDictionary *listViewDef = [listPageMetadata objectForKey:@"view_definition"];	
	listLayoutStr = [listViewDef valueForKey:@"mobile_layout"];
	listLayout = [[listLayoutStr JSONValue] copy];
	
	editorPageMetadata = [[MetadataService sharedInstance] getPageMetadata: editorPageName];
	NSDictionary *editorViewDef = [editorPageMetadata objectForKey:@"view_definition"];	
	editorLayoutStr = [editorViewDef valueForKey:@"mobile_layout"];
	editorLayout = [[editorLayoutStr JSONValue] copy];
		
	self.defaultEntityName = [[listViewDef objectForKey:@"default_entity"] copy];
	self.defaultEntityProperties = [[NSMutableDictionary alloc] init];
	
	NSArray *dataQueries = [listPageMetadata valueForKey:@"data_queries"];
	for(NSDictionary *result in dataQueries) {   
		
		NSString *dqName = [result objectForKey:@"name"];
		dataQuery = [[[MetadataService sharedInstance] getDataQuery:dqName] copy];	
		
		NSArray *entityMetadatas = [dataQuery objectForKey:@"entity_metadatas"];	
		for(NSDictionary *em in entityMetadatas) {   
			
			NSString *entityName = [em objectForKey:@"name"];
			if (NSOrderedSame == [entityName compare:self.defaultEntityName]) {
				
				NSArray *entityPropertyMetadatas = [em objectForKey:@"entity_property_metadatas"];	
				for(NSDictionary *ep in entityPropertyMetadatas) {   
					
					NSString *propertyName = [[ep objectForKey:@"name"] copy]; 
					[self.defaultEntityProperties setObject:[ep copy] forKey:propertyName];
				}
				break;
			}
			
		}
	}		
}

-(NSString *) description {
	return [NSString stringWithFormat:@"listPageMetadata=%@, editorPageMetadata=%@, properties=%@\n",
			listPageMetadata, editorPageMetadata, defaultEntityProperties];
}

@end
