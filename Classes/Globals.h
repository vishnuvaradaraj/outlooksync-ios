//
//  Globals.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 17/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Three20/Three20.h"
#import "LogoutService.h"

//Production server
#define DEFAULT_HOST_ADDRESS			@"http://parabaydata.appspot.com"
#define DEFAULT_SECURE_HOST_ADDRESS		@"https://parabaydata.appspot.com"

//Test server
//#define DEFAULT_HOST_ADDRESS			@"http://192.168.0.103:8080"
//#define DEFAULT_SECURE_HOST_ADDRESS		@"http://192.168.0.103:8080"


#define LoginDoneNotification			@"LoginDoneNotification"
#define LogoutDoneNotification			@"LogoutDoneNotification"
#define RegistrationDoneNotification	@"RegistrationDoneNotification"
#define DataListLoadedNotification		@"DataListLoadedNotification"
#define DataListReloadNotification		@"DataListReloadNotification"
#define DataSavedNotification			@"DataSavedNotification"
#define PropertyEditorNotification		@"PropertyEditorNotification"

#define ServerFileSavedNotification		@"ServerFileSavedNotification"
#define ServerFileLoadedNotification		@"ServerFileLoadedNotification"

#define ServerDataSavedNotification		@"ServerDataSavedNotification"
#define ServerDataDeletedNotification	@"ServerDataDeletedNotification"
#define ServerLocationSavedNotification		@"ServerLocationSavedNotification"

#define SubMetadataLoadedNotification	@"SubMetadataLoadedNotification"
#define MetadataLoadedNotification		@"MetadataLoadedNotification"

//NOT USED
#define BeginNetworkUsageNotification	@"BeginNetworkUsageNotification"
#define EndNetworkUsageNotification		@"EndNetworkUsageNotification"

#define kLastStoreUpdateKey				@"UD_LastUpdate_%@"
#define kClientVersion					@"1.0"
#define kClientVersionKey				@"client_version"

#define kParabayMeta1					@"ParabayMetaV1"
#define kParabayMeta2					@"ParabayMetaV2"

#define kParabayData0					@"Parabay.sqlite"

#define kParabayData1					@"ParabayV1.sqlite"
#define kParabayData2					@"ParabayV2.sqlite"

#define kParabayApp						@"ParabayOrg-Outlook"
//@"ParabayOrg-Timmy"
#define kParabayDefaultApp				@"ParabayOrg-Outlook"
#define kImagePropertyPrefix			@"Image%@"

#define kLastDeviceTokenUpdateKey		@"UD_LastDeviceTokenUpdate"
#define kCurrentSchemaVersion			2


#define TOTAL_METADATA_REQUESTS			15

#define PARABAY_ERROR_DOMAIN @"parabay.com"
#define kLogFilePath	@"parabay.log"

#define PB_EC_INVALID_STATUS 101

#define PB_SAFE_COPY(__POINTER) ((__POINTER == nil) ? __POINTER : [__POINTER copy]);

enum {
	RecordStatusSynchronized = 0,
	RecordStatusUpdated = 1,
	RecordStatusDeleted = 2	
};
typedef NSUInteger RecordStatus;

@interface Globals : NSObject {
	
	UIImage *photoDefault;
	NSDateFormatter *dateFormatter;
	NSDateFormatter *timeFormatter;
	NSString *appName;
	
}

@property (nonatomic, retain) NSDateFormatter *dateFormatter;
@property (nonatomic, retain) NSDateFormatter *timeFormatter;
@property (nonatomic, retain) UIImage *photoDefault;
@property (nonatomic, retain) NSString *appName;

+ (Globals*)sharedInstance;

- (UIImage *)defaultImage;
- (void)showSpinner:(UIView *)view;
- (void)hideSpinner:(UIView *)view;
- (void)displayError:(NSString *)error;
- (void)displayInfo:(NSString *)msg;
- (NSMutableDictionary *) convertNSManagedObjectToDictionary: (NSManagedObject *)managedObject;
- (NSManagedObject *) convertDictionaryToNSManagedObject: (NSDictionary *)dict withManagedObject: (NSManagedObject *)managedObject;
- (void)logout;
- (UIImage *)resizeImage: (UIImage *)selectedImage withMaxSize:(float)maxSize;
- (UIImage *)thumbnailForProperty:(NSString *)propertyName inItem: (NSManagedObject *)item;
- (UIImage *)imageForProperty:(NSString *)propertyName inItem: (NSManagedObject *)item;
- (NSString *)imageFilePath: (NSString *)key;
- (NSString *)fileCacheDirectory;
- (NSString *)applicationDocumentsDirectory;
- (NSString *) md5:(NSString *)str;

@end
