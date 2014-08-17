//
//  ImagePickerController.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 01/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Three20/Three20.h"

@interface ImagePickerController : TTViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate> {

	UIImageView* imageView;
	BOOL showChooser;
	NSUInteger takePhoto;
	NSUInteger chooseExisting;
}

- (void)viewDidLoad;
- (void)viewDidAppear:(BOOL)animated;
-(void)popupActionSheet;
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo;
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;

@end
