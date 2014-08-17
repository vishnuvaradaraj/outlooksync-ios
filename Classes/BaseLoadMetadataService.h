//
//  BaseLoadMetadataService.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 18/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BaseService.h"

@protocol LoadMetadataDelegate <NSObject>
@optional
- (void)progressPending: (NSUInteger) pending withTotal: (NSUInteger) total;
@end

@interface BaseLoadMetadataService : BaseService<LoadMetadataDelegate> {

	NSString *name;
	NSMutableArray *subLoaders;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSMutableArray *subLoaders;

+ (void) metadataItemLoaded: (NSNotification *)aNotification;
+ (void)loadAllWithDelegate: (id<LoadMetadataDelegate>) callback;
+ (void) initialize;
+ (void)loadAll;
+ (void) setTotalRequests: (NSUInteger) totalReq;
@end
