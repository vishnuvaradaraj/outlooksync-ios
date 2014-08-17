//
//  TextEditorController.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 29/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Three20/Three20.h"

@interface TextEditorController : TTPostController<TTPostControllerDelegate> {
	NSString *propertyName;
}

@property (nonatomic, retain) NSString *propertyName;

- (void)viewWillAppear:(BOOL)animated;
- (id)initWithProperty:(NSString*)name query:(NSDictionary*)query;
- (BOOL)postController:(TTPostController*)postController willPostText:(NSString*)text;

@end
