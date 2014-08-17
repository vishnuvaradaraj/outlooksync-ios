//
//  SaveService.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 06/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseService.h"

@interface SaveService : BaseService {

	NSMutableArray *items;
	NSString *kind;
	NSArray *results;
}

@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, retain) NSString *kind;
@property (nonatomic, retain) NSArray *results;

- (BOOL)sendSaveRequest: (NSString *)pageName;

@end
