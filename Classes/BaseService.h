//
//  BaseService.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 18/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Three20/Three20.h>
#import "GTMNSDictionary+URLArguments.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"

@class BaseService;
@class PageData;

@protocol ServiceDelegate <NSObject>

@optional
- (void)service:(BaseService *) service withResult: (NSDictionary *)data;

// Notification posted by NSManagedObjectContext when saved.
- (void)serviceDidSave:(NSNotification *)saveNotification;
@end

@interface BaseService : ASIFormDataRequest {
	NSString *host;
	NSString *doneNotification;
	id <ServiceDelegate> serviceDelegate;
	
    NSManagedObjectContext *insertionContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSEntityDescription *entityDescription;
	
	NSString *pageName;
	PageData *pageData;	
	ASINetworkQueue *privateQueue;
}

@property (nonatomic, retain) NSString *host;
@property (nonatomic, retain) NSString *doneNotification;
@property (nonatomic, assign) id <ServiceDelegate> serviceDelegate;

@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectContext *insertionContext;
@property (nonatomic, retain, readonly) NSEntityDescription *entityDescription;

@property (nonatomic, retain) NSString *pageName;
@property (nonatomic, retain) PageData *pageData;
@property (nonatomic, retain) ASINetworkQueue *privateQueue;

+ (ASINetworkQueue*) sharedQueue;

- (void)execute;
- (void)loadData:(NSDictionary *)json;
- (void)forwardResult: (NSDictionary *)result;
- (void)requestFinished:(ASIHTTPRequest *)requestParam; //for send request
- (void)sendRequest: (NSString *)path withParameters: (NSDictionary *)parameters;
- (void)queueRequest: (NSString *)path withParameters: (NSDictionary *)parameters;
- (NSMutableDictionary *) convertNSManagedObjectToDictionary: (NSManagedObject *)managedObject;

@end
