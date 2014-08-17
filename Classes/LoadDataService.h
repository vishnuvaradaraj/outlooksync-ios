//
//  LoadDataService.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-11-27.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseService.h"

@class RelatedEntityLinker;

@interface LoadDataService : BaseService {

	NSUInteger offset;
	RelatedEntityLinker *relatedPropertyLinker;
}

@property (nonatomic) NSUInteger offset;
@property (nonatomic, retain) RelatedEntityLinker *relatedPropertyLinker;

- (NSString *) queryToSynch: (NSDictionary *)dataQueryObject;
- (BOOL) sendLoadRequest: (NSString *)page withOffset: (NSUInteger) offset;

@end
