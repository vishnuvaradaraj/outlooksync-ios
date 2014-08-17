//
//  AboutController.h
//  LoginApp
//
//  Created by Vishnu Varadaraj on 10/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Three20/Three20.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface AboutController : TTTableViewController<MFMailComposeViewControllerDelegate> {

}

- (UIViewController*)displayComposerSheet:(NSDictionary*)query;

@end
