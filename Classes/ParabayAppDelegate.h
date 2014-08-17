//
//  ParabayAppDelegate.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 17/08/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "Three20/Three20.h"
#import "Globals.h"
#import "EntityLoader.h"
#import "AdMobDelegateProtocol.h"
#import "StoreFrontDelegate.h"

//Update these definitions based on the values you get from the iLime Admin Console
#define ILIME_APP_USER @"support@parabay.com"
#define ILIME_APP_PASSWORD @"sa1985"
#define ILIME_ACCOUNT_ID 1
#define ILIME_APP_ID 1

#define AD_REFRESH_PERIOD 180.0 // display fresh ads once per minute

@class AdMobView;
@protocol ServiceDelegate;

@interface ParabayAppDelegate : NSObject <UIApplicationDelegate, ServiceDelegate, AdMobDelegate, StoreFrontDelegate> {

    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSString *persistentStorePath;	

	NSMutableArray *importers;
	
    UIWindow *window;
	UIView *progressOverlay;
	UILabel *progressMessage;
	
	UIView *adHostView;
	AdMobView *adMobAd;
	NSTimer *refreshTimer;	
	
	NSEntityDescription *delEntityDescription;
	
	NSString *deviceToken;
	NSString *deviceAlias;	
}

- (IBAction)saveAction:sender;
- (void) clearUserData;
- (void)pingServer: (NSOperationQueue *) queue;
- (NSDictionary *) entityPropertyMetadataForEntity: (NSString *)entityName withProperty: (NSString *)propertyName;

- (void) startAdQueryFromHostView: (UIView *)hostView;
- (void) stopAdQueryFromHostView: (UIView *)hostView;
- (void) auditDeletion: (NSString *)entityName withId:  (NSString *)key;
- (void) migrateStoreIfRequired;
- (BOOL) migrateStore:(NSURL *)storeURL toUpdatedStore:(NSURL *)dstStoreURL fromVersion:(NSInteger) oldVersion;
- (void)registerDeviceIfNecessary;
- (NSString *)normalizedEmail;
- (NSString *)normalizedAppName;

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSString *persistentStorePath;

@property (nonatomic, retain) NSMutableArray *importers;

@property (nonatomic, readonly) NSString *applicationDocumentsDirectory;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIView *progressOverlay;
@property (nonatomic, retain) IBOutlet UILabel *progressMessage;

@property (nonatomic, retain) UIView *adHostView;
@property (nonatomic, retain, readonly) NSEntityDescription *delEntityDescription;

@property (nonatomic, retain) NSString *deviceToken;
@property (nonatomic, retain) NSString *deviceAlias;

@end

