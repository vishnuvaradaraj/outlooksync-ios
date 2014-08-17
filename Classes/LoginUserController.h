//
//  LoginUserController.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 18/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Three20/Three20.h"
#import "LoginService.h"

@interface LoginUserController : TTTableViewController<UITextFieldDelegate> {
	
	UITextField* userName;
	UITextField* password;
	UIButton* button;
}

- (void)processAction;
- (void)createControls;

@property (nonatomic, retain, readonly) UITextField* userName;
@property (nonatomic, retain, readonly) UITextField* password;
@property (nonatomic, retain) UIButton* button;

@end
