//
//  LoadFileService.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-11-29.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseService.h"

@interface LoadFileService : BaseService {
	
	NSUInteger offset;
	NSEntityDescription *imgEntityDescription;
	
}

@property (nonatomic) NSUInteger offset;
@property (nonatomic, retain, readonly) NSEntityDescription *imgEntityDescription;

- (BOOL) sendLoadRequestWithOffset: (NSUInteger) offsetParam;

@end
