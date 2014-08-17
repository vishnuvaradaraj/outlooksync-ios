//
//  SyncService.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-12-09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseService.h"

@interface SyncService : BaseService {

	NSEntityDescription *syncEntityDescription;
}

+ (SyncService*)sharedInstance;

- (NSString *)userName;
- (NSString *) fetchServerTokenForKind: (NSString *)kind;
- (void) updateServerToken: (NSString *)serverToken forKind: (NSString *)kind;

@property (nonatomic, retain, readonly) NSEntityDescription *syncEntityDescription;

@end
