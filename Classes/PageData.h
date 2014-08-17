//
//  PageData.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-10-04.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PageData : NSObject {
	NSString *pageName;
	NSString *editorPageName;
	NSDictionary *listPageMetadata;
	NSDictionary *editorPageMetadata;
	NSString *listLayoutStr;
	NSString *editorLayoutStr;
	NSDictionary *listLayout;
	NSDictionary *editorLayout;
	NSString *defaultEntityName;
	NSDictionary *dataQuery;
	NSDictionary *defaultEntityMetadata;
	NSMutableDictionary *defaultEntityProperties;
}

@property (nonatomic, retain) NSString *pageName;
@property (nonatomic, retain) NSString *editorPageName;
@property (nonatomic, retain) NSDictionary *listPageMetadata;
@property (nonatomic, retain) NSDictionary *editorPageMetadata;
@property (nonatomic, retain) NSString *listLayoutStr;
@property (nonatomic, retain) NSString *editorLayoutStr;
@property (nonatomic, retain) NSDictionary *listLayout;
@property (nonatomic, retain) NSDictionary *editorLayout;
@property (nonatomic, retain) NSString *defaultEntityName;
@property (nonatomic, retain) NSDictionary *dataQuery;
@property (nonatomic, retain) NSDictionary *defaultEntityMetadata;
@property (nonatomic, retain) NSMutableDictionary *defaultEntityProperties;

-(void) loadPageData;

@end
