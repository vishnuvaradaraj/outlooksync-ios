//
//  MetadataService.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 18/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseService.h"

@class MetadataCache;
@protocol LoadMetadataDelegate;

@interface MetadataDatabase : NSObject {

	NSString *databaseName;
	NSEntityDescription *cacheEntityDescription;
	
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
	
}

@property (nonatomic, retain) NSString *databaseName;
@property (nonatomic, retain, readonly) NSEntityDescription *cacheEntityDescription;

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, readonly) NSString *applicationDocumentsDirectory;

+ (MetadataDatabase*)sharedInstanceWithDatabaseName: (NSString *)dbName;

- (void)dumpCache;
- (void)removeOldCacheEntries:(NSString *)key;
- (void)refreshMetadataFromServer:(id<LoadMetadataDelegate>)callback;
- (MetadataCache *)fetchCacheEntry:(NSString *)key;
- (NSMutableArray *)fetchDataQueries;

@end
