//
//  LocationLoader.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-11-24.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreData/CoreData.h>
#import "BaseService.h"
#import "Three20/Three20.h"
#import "LoadLocationService.h"

@interface LocationLoader : NSOperation<ServiceDelegate> {
	
    BOOL done;
    NSAutoreleasePool *importPool;
    NSManagedObjectContext *insertionContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSEntityDescription *entityDescription;
	
	LoadLocationService *loadLocationService;
	NSArray *results;
}

@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectContext *insertionContext;
@property (nonatomic, retain, readonly) NSEntityDescription *entityDescription;

@property (nonatomic, retain) LoadLocationService *loadLocationService;
@property (nonatomic, retain) NSArray *results;

- (void)sendLoadRequest;
- (void) updateLocations;

@end
