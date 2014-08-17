//
//  EntityEditorController.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 30/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Three20/Three20.h"
#import "MBProgressHUD.h"

@class PageData;

@interface EntityEditorController : TTTableViewController<UITextFieldDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIActionSheetDelegate, MBProgressHUDDelegate> {
	NSManagedObject *item;
	
	NSString *pageName;
	PageData *pageData;	
	NSManagedObjectContext *managedObjectContext;
	NSEntityDescription *entityDescription;
	
	NSMutableDictionary *propertyEditors;
	BOOL hasSaved;
	NSUInteger chooseExisting;
	NSString *editingImageProperty;
	
	MBProgressHUD *HUD;
}

@property (nonatomic, retain) NSManagedObject *item;

@property (nonatomic, retain) NSString *pageName;
@property (nonatomic, retain) PageData *pageData;	
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSEntityDescription *entityDescription;
@property (nonatomic, retain) NSMutableDictionary *propertyEditors;
@property (nonatomic) BOOL hasSaved;

- (void)updateTextFields;
- (NSManagedObject *)itemWithKey: (NSString *)name;
- (void)setItem:(NSManagedObject*)aValue;
- (id)initWithViewMap:(NSString*)name query:(NSDictionary*)query;

-(void)popupActionSheet; //:(NSString*)propertyName;
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)selectedImage editingInfo:(NSDictionary *)editingInfo;
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;

@end
