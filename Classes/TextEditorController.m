//
//  TextEditorController.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 29/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TextEditorController.h"
#import "EntityEditorController.h"

@implementation TextEditorController

@synthesize propertyName;

- (id)initWithProperty:(NSString*)name query:(NSDictionary*)query {
	
	self.propertyName = name;
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:query];
	[dict setObject:self forKey:@"delegate"];
	
	return [super initWithNavigatorURL:nil	query: dict];	
}		

- (void)viewWillAppear:(BOOL)animated {
	
	self.navigationItem.title = [NSString stringWithFormat: @"Edit %@", self.propertyName];
	if ([self.superController isKindOfClass:[EntityEditorController class]]) {
		
		EntityEditorController *parent = (EntityEditorController *)self.superController;
		_defaultText = [[parent.item valueForKey: self.propertyName] copy];
	}
	
}

- (BOOL)postController:(TTPostController*)postController willPostText:(NSString*)text {
		
	if ([self.superController isKindOfClass:[EntityEditorController class]]) {
		
		EntityEditorController *parent = (EntityEditorController *)self.superController;
		[parent.item setValue:text forKey:propertyName];
		parent.item = parent.item;
		[parent.tableView reloadData];
	}
	
	return YES;
}

@end
