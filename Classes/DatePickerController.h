//
//  DatePickerController.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 29/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Three20/Three20.h"

@class EntityEditorController;

@interface DatePickerController : TTTableViewController
{
@private
	UIDatePicker *pickerView;
	
	NSDateFormatter *dateFormatter;
	NSString *propertyName;
	UIDatePickerMode datePickerMode;
	
	UITextField* textField;
	
	EntityEditorController *parentEditor;
	NSDateFormatter *timeFormatter;
}

@property (nonatomic) UIDatePickerMode datePickerMode;
@property (nonatomic, retain) NSString *propertyName;
@property (nonatomic, retain) UIDatePicker *pickerView; 
@property (nonatomic, retain) NSDateFormatter *dateFormatter; 
@property (nonatomic, retain) UITextField* textField;
@property (nonatomic, retain) EntityEditorController *parentEditor;
@property (nonatomic, retain) NSDateFormatter *timeFormatter; 

- (NSDate *)dateAsTimeWithoutSeconds: (NSDate *)date;
- (NSDate *)dateAsDateWithoutTime: (NSDate *)date;
- (NSDate *) normalizeDate: (NSDate *)date;

- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;

- (void)cancelAction;
- (void)doneAction:(id)sender;	// when the done button is clicked
- (void)dateAction:(id)sender;	// when the user has changed the date picke values (m/d/y)

@end
