//
//  EntitySaver.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 06/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreData/CoreData.h>
#import "BaseService.h"
#import "Three20/Three20.h"
#import "SaveService.h"
#import "DeleteService.h"

@class EntitySaver;
@class PageData;

@interface EntitySaver : NSOperation<ServiceDelegate> {
	
    BOOL done;
    NSAutoreleasePool *importPool;
    NSManagedObjectContext *insertionContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSEntityDescription *entityDescription;

	NSString *pageName;
	PageData *pageData;

	SaveService *saveService;
	NSArray *results;
}

@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectContext *insertionContext;
@property (nonatomic, retain, readonly) NSEntityDescription *entityDescription;

@property (nonatomic, retain) NSString *pageName;
@property (nonatomic, retain) PageData *pageData;

@property (nonatomic, retain) SaveService *saveService;
@property (nonatomic, retain) NSArray *results;

- (void)sendSaveRequest;
- (void) updateSaveStatus;
- (NSMutableDictionary *) convertNSManagedObjectToDictionary: (NSManagedObject *)managedObject;

@end
