//
//  LoginService.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 18/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BaseService.h"

@interface LoginService  : BaseService {

	NSString *user;
	NSString *passwd;
}

@property (nonatomic, retain) NSString *user;
@property (nonatomic, retain) NSString *passwd;

@end
