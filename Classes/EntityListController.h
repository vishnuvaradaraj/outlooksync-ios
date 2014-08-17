//
//  EntityListController.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 19/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Three20/Three20.h"
#import <CoreLocation/CoreLocation.h>
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"
#import <GameKit/GameKit.h>

#define AMIPHD_P2P_SESSION_ID @"amiphd-p2p"

@class PageData;
@class EntityDetailsController;

@interface EntityListController : UITableViewController <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UISearchDisplayDelegate, UISearchBarDelegate, CLLocationManagerDelegate, GKSessionDelegate, GKPeerPickerControllerDelegate> {

	UITableView *tableView;
	EntityDetailsController *editController;
	NSFetchedResultsController *fetchedResultsController;
	NSFetchedResultsController *searchResultsController;
	UISearchDisplayController *searchController;
	NSManagedObjectContext *managedObjectContext;
	
	NSString *pageName;	
	PageData *pageData;
	NSDictionary *pageMetadata;	
	NSString *layout;
	NSString *entityMetadata;
	NSString *cellType;
	NSMutableDictionary *propertyMetadatas;
	NSDictionary *mobileLayout;	
	
	NSString *sectionKeyPath;
	NSArray *sortDescList;
	
	UIToolbar	*toolbar;
	NSMutableArray *toolbarItems;
	
	UIBarButtonItem *refreshButtonItem;
	UIBarButtonItem *statusButtonItem;
	UIBarButtonItem *activityButtonItem;
		
	NSTimer *timer;
	NSString *searchTerm;
	NSString *searchFields;
	NSString *indexField;
	
	BOOL isReadOnly;
	CLLocationManager *locationManager;
	NSMutableDictionary *sectionIndexes;
	ASINetworkQueue *privateQueue;
	
	GKSession *gkSession;
	NSString *peerID;
	BOOL actingAsHost;
	BOOL isConnected;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSFetchedResultsController *searchResultsController;
@property (nonatomic, retain) UISearchDisplayController *searchController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) EntityDetailsController *editController;

@property (nonatomic, retain) NSString *pageName;
@property (nonatomic, retain) PageData *pageData;
@property (nonatomic, retain) NSDictionary *pageMetadata;
@property (nonatomic, retain) NSString *layout;
@property (nonatomic, retain) NSString *entityMetadata;
@property (nonatomic, retain) NSString *cellType;
@property (nonatomic, retain) NSMutableDictionary *propertyMetadatas;
@property (nonatomic, retain) NSDictionary *mobileLayout;

@property (nonatomic, retain) NSString *sectionKeyPath;
@property (nonatomic, retain) NSArray *sortDescList;
@property (nonatomic, retain) UIToolbar	*toolbar;
@property (nonatomic, retain) NSMutableArray *toolbarItems;

@property (nonatomic, retain) UIBarButtonItem *refreshButtonItem;
@property (nonatomic, retain) UIBarButtonItem *statusButtonItem;
@property (nonatomic, retain) UIBarButtonItem *activityButtonItem;

@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) NSString *searchTerm;
@property (nonatomic, retain) NSString *searchFields;
@property (nonatomic, retain) NSString *indexField;
@property (nonatomic) BOOL isReadOnly;

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) NSMutableDictionary *sectionIndexes;
@property (nonatomic, retain) ASINetworkQueue *privateQueue;

@property (nonatomic, retain) GKSession *gkSession;
@property (nonatomic, retain) NSString *peerID;

- (void)fetch;
- (void)refresh:(id)sender;
- (void)refreshIfNecessary;
- (void) updateStatusText;

- (void)viewDidAppear:(BOOL)animated;
- (void)viewDidDisappear:(BOOL)animated;
- (void)handleSaveNotification:(NSNotification *)aNotification;

- (id)initWithViewMap:(NSString*)name query:(NSDictionary*)query;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)table;
- (Class)tableView:(UITableView*)tableView cellClassForObject:(id)object;
- (TTTableItem *)tableItemForCellClass:(Class)klazz withData: (NSManagedObject *)data;

@end
