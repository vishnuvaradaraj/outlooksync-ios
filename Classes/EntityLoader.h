//
//  EntityLoader.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 19/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Three20/Three20.h"

@class EntityLoader;
@class PageData;

@protocol EntityLoaderDelegate <NSObject>
@optional
// Notification posted by NSManagedObjectContext when saved.
- (void)importerDidSave:(NSNotification *)saveNotification;
// Called by the importer in the case of an error.
- (void)importer:(EntityLoader *)importer didFailWithError:(NSError *)error;
// Called by the importer when cancelled.
- (void)importer:(EntityLoader *)importer cancelledRequest:(NSString *)status;
@end

@interface EntityLoader : NSOperation<TTURLRequestDelegate, TTURLResponse> {
	
    BOOL done;
	id <EntityLoaderDelegate> delegate;
	NSUInteger countForCurrentBatch;
    NSAutoreleasePool *importPool;
    NSManagedObjectContext *insertionContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSEntityDescription *entityDescription;
    NSURL *dataURL;
	
	NSString *host;
	NSString *pageName;
	PageData *pageData;
	NSUInteger offset;
	NSString *doneNotification;	
	
}

@property (nonatomic, retain) NSURL *dataURL;
@property (nonatomic, assign) id <EntityLoaderDelegate> delegate;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectContext *insertionContext;
@property (nonatomic, retain, readonly) NSEntityDescription *entityDescription;

@property (nonatomic, retain) NSString *host;
@property (nonatomic, retain) NSString *pageName;
@property (nonatomic, retain) PageData *pageData;
@property (nonatomic) NSUInteger offset;
@property (nonatomic, retain) NSString *doneNotification;


- (NSString *) queryToSynch: (NSString *)queryString;

@end
