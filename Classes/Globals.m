//
//  Globals.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 17/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Globals.h"
#import "ParabayAppDelegate.h"
#import <CommonCrypto/CommonDigest.h>

static Globals* SharedInstance;

@implementation Globals

@synthesize dateFormatter, timeFormatter, photoDefault, appName;

+ (Globals*)sharedInstance {
	if (!SharedInstance)
        SharedInstance = [[Globals alloc] init]; 
	
    return SharedInstance;
}

- (id)init {
	if (self = [super init]) {
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		appName = [defaults stringForKey:@"app_preference"];
		if (!appName) {
			appName = kParabayApp;
		}
	}
	return self;
}

- (NSDateFormatter *)dateFormatter {
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    }
    return dateFormatter;
}

- (NSDateFormatter *)timeFormatter {
    if (timeFormatter == nil) {
        timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setDateStyle:NSDateFormatterNoStyle];
        [timeFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return timeFormatter;
}

- (void)addProgressIndicator:(UIView *)view {
	
	ParabayAppDelegate *appDelegate = (ParabayAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    [view addSubview:appDelegate.progressOverlay];
    appDelegate.progressOverlay.alpha = 0.0;
    [view bringSubviewToFront:appDelegate.progressOverlay];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:view cache:YES];
    appDelegate.progressOverlay.alpha = 0.7;
    [UIView commitAnimations];	
}

- (void)removeProgressIndicator:(UIView *)view {
	
	ParabayAppDelegate *appDelegate = (ParabayAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:view cache:YES];
    [UIView setAnimationDelegate:self];
    appDelegate.progressOverlay.alpha = 0.0;
    [UIView commitAnimations];
	
    [appDelegate.progressOverlay removeFromSuperview];	
}

- (void)showSpinner:(UIView *)view {
    [self performSelectorInBackground:@selector(addProgressIndicator:) withObject:view];
}

- (void)hideSpinner:(UIView *)view {
    [self performSelectorInBackground:@selector(removeProgressIndicator:) withObject:view];
}


- (void)displayError:(NSString *)error {
	
	UIAlertView* errorAlertView = [[[UIAlertView alloc] initWithTitle:
									@"Error"
															  message:error
															 delegate:self
													cancelButtonTitle:@"Cancel"
													otherButtonTitles:nil, nil] autorelease];
	[errorAlertView show];
}

- (void)displayInfo:(NSString *)msg {
	
	UIAlertView* infoAlertView = [[[UIAlertView alloc] initWithTitle:
								   @"Information"
															 message:msg
															delegate:self
												   cancelButtonTitle:@"Ok"
												   otherButtonTitles:nil, nil] autorelease];
	[infoAlertView show];
}

- (void)logout {
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	
	LogoutService *logout = [[LogoutService alloc] init];
	logout.token = [defaults objectForKey:@"UD_TOKEN"];
	[logout execute];
		
	TTOpenURL(@"tt://login");
}

- (NSMutableDictionary *) convertNSManagedObjectToDictionary: (NSManagedObject *)managedObject {
	
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	
	NSEntityDescription *entityDesc = [managedObject entity]; 
	for (NSPropertyDescription *propDesc in entityDesc) {
		
		NSString *propertyName = [propDesc name];
		id value = [managedObject valueForKey:propertyName];
		if (value) {
			[dict setObject:value forKey:propertyName];
		}	
	}		
	
	NSLog(@"mo->dict=%@", dict);
	return dict;
}

- (NSManagedObject *) convertDictionaryToNSManagedObject: (NSDictionary *)dict withManagedObject: (NSManagedObject *)managedObject {	
	
	NSEntityDescription *entityDesc = [managedObject entity]; 
	for (NSPropertyDescription *propDesc in entityDesc) {
		NSString *propertyName = [propDesc name];
		id value = [dict valueForKey:propertyName];
		if (value) {
			[managedObject setValue:value forKey:propertyName];
		}	
	}		
	
	NSLog(@"dict->mo=%@", dict);
	return managedObject;
}

- (UIImage *)resizeImage: (UIImage *)selectedImage withMaxSize:(float)maxSize {
	
	// Create a thumbnail version of the image.
	CGSize size = selectedImage.size;
	if (size.width > maxSize || size.height > maxSize) {
		CGFloat ratio = 0;
		if (size.width > size.height) {
			ratio = maxSize / size.width;
		} else {
			ratio = maxSize / size.height;
		}
		CGRect rect = CGRectMake(0.0, 0.0, ratio * size.width, ratio * size.height);
		
		UIGraphicsBeginImageContext(rect.size);
		[selectedImage drawInRect:rect];
		UIImage *thumbNail = UIGraphicsGetImageFromCurrentImageContext();
		return thumbNail;
	}
	else {
		return selectedImage;
	}

}

- (UIImage *)defaultImage {
	
	if (!photoDefault) {
		photoDefault = [[self resizeImage:[UIImage imageNamed:@"photoDefault.png"] withMaxSize:44.0] retain];
	}
	return photoDefault;
}

- (UIImage *)thumbnailForProperty:(NSString *)propertyName inItem: (NSManagedObject *)item {
	
	UIImage *ret = [[Globals sharedInstance] defaultImage];
	NSManagedObject *imageRow = [item valueForKey:propertyName];
	
	if (imageRow && ([NSNull null] != (NSNull *)imageRow) ) {
		
		ret = [imageRow valueForKey:@"thumbnail"];		
	}
	
	return ret;
}

- (UIImage *)imageForProperty:(NSString *)propertyName inItem: (NSManagedObject *)item {
	
	UIImage *ret = [[Globals sharedInstance] defaultImage];
	NSManagedObject *imageRow = [item valueForKey:propertyName];
	
	if (imageRow && ([NSNull null] != (NSNull *)imageRow) ) {
		
		NSString *cacheFilePath = [imageRow valueForKey:@"cacheFilePath"];
		NSLog(@"Retrieved path: %@", cacheFilePath);
		
		UIImage *imageData = [UIImage imageWithContentsOfFile: [self imageFilePath: cacheFilePath]];
		if (imageData) {
			ret = imageData;
		}		
	}
	
	return ret;
}

- (NSString *)applicationDocumentsDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath copy];
}

- (NSString *)fileCacheDirectory {
	
	BOOL isDir;
	NSError *error = nil;
	
	NSString *documentsDirectory = [self applicationDocumentsDirectory];
	NSString *fileCachePath = [ documentsDirectory stringByAppendingPathComponent: @"FileCache"];
			
	if (!([[NSFileManager defaultManager]  fileExistsAtPath: fileCachePath isDirectory:&isDir] && isDir)) {
		
		BOOL result = [[NSFileManager defaultManager] createDirectoryAtPath:fileCachePath withIntermediateDirectories:YES attributes:nil error: &error];
		if (!result)
			NSLog(@"Unhandled error creating folder %s at line %d: %@", __FUNCTION__, __LINE__, [error localizedDescription]);
	}
		
    return fileCachePath;
}

- (NSString *)imageFilePath: (NSString *)key {

	NSString *imagePath = [self fileCacheDirectory];
	return [imagePath stringByAppendingPathComponent: key];
}
	
- (NSString *) md5:(NSString *)str {
	const char *cStr = [str UTF8String];
	unsigned char result[16];
	CC_MD5( cStr, strlen(cStr), result );
	return [NSString stringWithFormat:
			@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			];	
}

- (void)dealloc {
	
	[super dealloc];
}

@end
