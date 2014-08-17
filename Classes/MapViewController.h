//
//  MapViewController.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 01/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Three20/Three20.h"

@interface MapViewController : TTViewController<MKMapViewDelegate, CLLocationManagerDelegate> {

	MKMapView *mapView;
	CLLocationManager *locationManager;
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSManagedObjectContext *insertionContext;
	NSEntityDescription *locEntityDescription;	
	
	CLLocationCoordinate2D currentLocationCoordinate;
}

@property (nonatomic, retain) MKMapView *mapView;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectContext *insertionContext;
@property (nonatomic, retain, readonly) NSEntityDescription *locEntityDescription;
@property (nonatomic) CLLocationCoordinate2D currentLocationCoordinate;

- (void)recenterMap;
- (void) addLocalAnnotations: (CLLocationCoordinate2D) location;
- (NSString *)calculateGeoHash: (CLLocationCoordinate2D) location;

@end

double calculateDistance( double nLat1, double nLon1, double nLat2, double nLon2 );
void encode_geohash(double latitude, double longitude, int precision, char *geohash);