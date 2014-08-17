//
//  ImagePickerController.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 01/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ImagePickerController.h"
#import "SearchResultsModel.h"
#import "Reachability.h"

@implementation ImagePickerController

//@synthesize takePhoto, chooseExisting;

- (void)viewDidLoad {
    
	[super viewDidLoad];
			
	// Set up the image view and add it to the view but make it hidden
	imageView = [[UIImageView alloc] initWithFrame:[self.view bounds]];
	[self.view addSubview:imageView];

	showChooser = YES;
	
}

- (void)viewDidAppear:(BOOL)animated {
	
	if (showChooser) {
		[self popupActionSheet];
		showChooser = NO;
	}
}

-(void)popupActionSheet {
    UIActionSheet *popupQuery = [[UIActionSheet alloc]
								 initWithTitle:nil
								 delegate:self
								 cancelButtonTitle:@"Cancel"
								 destructiveButtonTitle:nil
								 otherButtonTitles:nil];
	
	takePhoto = 0;
	chooseExisting = 1;
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		[popupQuery addButtonWithTitle:@"Take Photo"];
		chooseExisting = 2;
	}
	[popupQuery addButtonWithTitle:@"Choose Existing Photo"];
	
	NetworkStatus status = [[Reachability sharedReachability] internetConnectionStatus];
	if (NotReachable != status) {
		[popupQuery addButtonWithTitle:@"Search On Server"];
	}
	
    [popupQuery showInView:imageView];
    [popupQuery release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex == 0) {
		NSLog(@"Cancel");
	}
	else if (buttonIndex <= chooseExisting) {
		
		// Choose existing photo
		UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
		imagePicker.sourceType = ((buttonIndex == 0) ? UIImagePickerControllerSourceTypeCamera :  UIImagePickerControllerSourceTypePhotoLibrary);
		imagePicker.delegate = self;
		[self presentModalViewController:imagePicker animated:YES];
		[imagePicker release];	
		
	}
	else if (buttonIndex == chooseExisting+1) {
		
		SearchResultsModel *photoSource = [[SearchResultsModel alloc] init];	
		[photoSource setSearchTerms:@"nature"];    
		[photoSource setSource:SearchSourceYahoo];
		[photoSource load:TTURLRequestCachePolicyDefault more:NO];
		
		TTThumbsViewController *thumbs = [[TTThumbsViewController alloc] init];
		[thumbs setPhotoSource:photoSource];
		[self.navigationController pushViewController:thumbs animated:YES];
		[thumbs release];		
	}
}

- (void)dealloc
{
	[imageView release];
	[super dealloc];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
	 imageView.image = image;
	 [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	 [self dismissModalViewControllerAnimated:YES];
}

@end
