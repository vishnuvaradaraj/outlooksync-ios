//
//  ListPickerController.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 29/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Three20/Three20.h"

@interface ListPickerController : TTTableViewController<UIPickerViewDelegate, UIPickerViewDataSource> {
@private
	UIPickerView *pickerView;	
	NSString *propertyName;
	UITextField* textField;
	NSArray				*pickerViewArray;
	
}

@property (nonatomic, retain) NSString *propertyName;
@property (nonatomic, retain) UIPickerView *pickerView; 
@property (nonatomic, retain) UITextField* textField;
@property (nonatomic, retain) NSArray	*pickerViewArray;

- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;

- (void)cancelAction;
- (void)doneAction:(id)sender;	// when the done button is clicked
- (CGRect)pickerFrameWithSize:(CGSize)size;

@end
