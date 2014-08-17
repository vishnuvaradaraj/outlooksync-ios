//
//  LogoutService.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 18/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseService.h"

@interface LogoutService : BaseService {
	NSString *token;
}

@property (nonatomic, retain) NSString *token;

@end
