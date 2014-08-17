//
//  EntityRemover.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 07/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreData/CoreData.h>
#import "BaseService.h"
#import "Three20/Three20.h"
#import "SaveService.h"
#import "DeleteService.h"

@class PageData;

@interface EntityRemover : NSOperation<ServiceDelegate> {
	
    BOOL done;
    NSAutoreleasePool *importPool;
    NSManagedObjectContext *insertionContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSEntityDescription *delEntityDescription;
	
	NSString *pageName;
	PageData *pageData;
	
	DeleteService *deleteService;	
	NSArray *results;
}

@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectContext *insertionContext;
@property (nonatomic, retain, readonly) NSEntityDescription *delEntityDescription;

@property (nonatomic, retain) NSString *pageName;
@property (nonatomic, retain) PageData *pageData;

@property (nonatomic, retain) DeleteService *deleteService;

@property (nonatomic, retain) NSArray *results;

- (void)sendDeleteRequest;

- (void) updateDeleteStatus;

@end
