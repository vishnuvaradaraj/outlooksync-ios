//
//  MapViewController.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 01/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MapViewController.h"
#import "ItemAnnotation.h" 
#import "ParabayAppDelegate.h"

@implementation MapViewController

@synthesize mapView, locationManager, persistentStoreCoordinator, insertionContext, locEntityDescription, currentLocationCoordinate;

static NSComparisonResult compareLocations(NSManagedObject *item1, NSManagedObject *item2, void *context) {
	
	double *currentLocation = (double *)context;
	
	NSManagedObject *locItem1 = [item1 valueForKey:@"Location"]; 
	NSManagedObject *locItem2 = [item2 valueForKey:@"Location"];
	if (locItem1 && locItem2) {	
		
		double latitude1 =  [[locItem1 valueForKey:@"latitude"] doubleValue];
		double longitude1= [[locItem1 valueForKey:@"longitude"] doubleValue];

		double latitude2 =  [[locItem2 valueForKey:@"latitude"] doubleValue];
		double longitude2= [[locItem2 valueForKey:@"longitude"] doubleValue];
		
		double dist1 = calculateDistance( currentLocation[0], currentLocation[1], latitude1, longitude1 );
		double dist2 = calculateDistance( currentLocation[0], currentLocation[1], latitude2, longitude2 );
		
		if (dist1 < dist2)
			return NSOrderedAscending;
		else if (dist1 > dist2)
			return NSOrderedDescending;		
		
	}

	return NSOrderedSame;
}

- (void)viewDidLoad {
    
	[super viewDidLoad];
	mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
	mapView.showsUserLocation = NO;
	mapView.mapType = MKMapTypeStandard;
	mapView.delegate = self;
	
	[self.view insertSubview:mapView atIndex:0];
	[[self locationManager] startUpdatingLocation];
}

- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];	
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger theme = [defaults integerForKey:@"theme_preference"];
	
	if (theme == 2) {
		UIApplication* app = [UIApplication sharedApplication];
		[app setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
		
		self.navigationController.navigationBar.tintColor = [UIColor 
															 blackColor]; 			
	}
	
}

- (void) viewDidAppear:(BOOL)animated {
	
	if(self.mapView.annotations.count > 1) {
		[self recenterMap];
	}	
}

- (NSString *)calculateGeoHash: (CLLocationCoordinate2D) location {
	char geohash[32];
	
	geohash[0] = '\0';
	encode_geohash(location.latitude, location.longitude, 13, (char *)geohash);
	
	NSString *ret = @"dpwxr9k3qh8us"; //[NSString stringWithCString:geohash encoding:NSASCIIStringEncoding];
	return ret;
}

- (void) addLocalAnnotations: (CLLocationCoordinate2D) location {
		
	NSString *geoHash = [self calculateGeoHash:location];
	
	NSFetchRequest *req = [[NSFetchRequest alloc] init];
	[req setEntity: self.locEntityDescription];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"Location.geohash beginswith[c] %@", [geoHash substringToIndex:3]];
	[req setPredicate:predicate];
	
	NSError *dataError = nil;
	NSArray *array = [self.insertionContext executeFetchRequest:req error:&dataError];
	if ((dataError != nil) || (array == nil)) {
		NSLog(@"Error while fetching\n%@",
			  ([dataError localizedDescription] != nil)
			  ? [dataError localizedDescription] : @"Unknown Error");
	}
	
	for(NSManagedObject *item in array) {
		
		NSManagedObject *locItem = [item valueForKey:@"Location"]; 
		if (locItem) {
			CLLocationCoordinate2D coordinate = {0.0f, 0.0f}; // start in the ocean
			coordinate.latitude =  [[locItem valueForKey:@"latitude"] doubleValue];
			coordinate.longitude= [[locItem valueForKey:@"longitude"] doubleValue];
			ItemAnnotation *newAnnotation = (ItemAnnotation *)[ItemAnnotation annotationWithCoordinate:coordinate];
			newAnnotation.title = [item valueForKey:@"Title"] ;
			newAnnotation.key = [item valueForKey:@"parabay_id"];
						
			[self.mapView addAnnotation:newAnnotation];
		}
	}
	
	double currentLocation[2];
	currentLocation[0] = self.currentLocationCoordinate.latitude;
	currentLocation[1] = self.currentLocationCoordinate.longitude;
	
	NSArray *sorted = [array sortedArrayUsingFunction:compareLocations context:currentLocation];
	for(NSManagedObject *item in sorted) {
		NSLog(@"%@", [item valueForKey:@"Title"]);
	}
	
	[req release];
	
}

- (void)setCurrentLocation:(CLLocation *)location {
	
	self.currentLocationCoordinate = location.coordinate;
	
	MKCoordinateRegion region = {{0.0f, 0.0f}, {0.0f, 0.0f}};
	region.center = location.coordinate;
	region.span.longitudeDelta = 0.10f;
	region.span.latitudeDelta = 0.10f;
	//[self.mapView setRegion:region animated:YES];
		
	[self addLocalAnnotations: location.coordinate];
	
	if(self.mapView.annotations.count > 1) {
		[self recenterMap];
	}	
}

- (void)recenterMap {
	
	NSArray *coordinates = [mapView valueForKeyPath:@"annotations.coordinate"];
	CLLocationCoordinate2D maxCoord = {-90.0f, -180.0f};
	CLLocationCoordinate2D minCoord = {90.0f, 180.0f};
	for(NSValue *value in coordinates) {
		CLLocationCoordinate2D coord = {0.0f, 0.0f};
		[value getValue:&coord];
		if(coord.longitude > maxCoord.longitude) {
			maxCoord.longitude = coord.longitude;
		}
		if(coord.latitude > maxCoord.latitude) {
			maxCoord.latitude = coord.latitude;
		}
		if(coord.longitude < minCoord.longitude) {
			minCoord.longitude = coord.longitude;
		}
		if(coord.latitude < minCoord.latitude) {
			minCoord.latitude = coord.latitude;
		}
	}
	MKCoordinateRegion region = {{0.0f, 0.0f}, {0.0f, 0.0f}};
	region.center.longitude = (minCoord.longitude + maxCoord.longitude) / 2.0;
	region.center.latitude = (minCoord.latitude + maxCoord.latitude) / 2.0;
	region.span.longitudeDelta = maxCoord.longitude - minCoord.longitude;
	region.span.latitudeDelta = maxCoord.latitude - minCoord.latitude;
	[self.mapView setRegion:region animated:YES];
}

#pragma mark Map View Delegate Methods

- (MKAnnotationView *)mapView:(MKMapView *)mView 
            viewForAnnotation:(id <MKAnnotation>)annotation {
	
	MKPinAnnotationView *view = nil; // return nil for the current user location
	if(annotation != mView.userLocation) {
		view = (MKPinAnnotationView *)[mView
									   dequeueReusableAnnotationViewWithIdentifier:@"identifier"];
		if(nil == view) {
			view = [[[MKPinAnnotationView alloc]
					 initWithAnnotation:annotation reuseIdentifier:@"identifier"]
					autorelease];
			view.rightCalloutAccessoryView = 
			[UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		}
		[view setPinColor:MKPinAnnotationColorGreen];
		[view setCanShowCallout:YES];
		[view setAnimatesDrop:YES];
	} else {
		CLLocation *location = [[CLLocation alloc] 
								initWithLatitude:annotation.coordinate.latitude
								longitude:annotation.coordinate.longitude];
		[self setCurrentLocation:location];
	}
	return view;
}

- (void)mapView:(MKMapView *)mapView 
 annotationView:(MKAnnotationView *)view
calloutAccessoryControlTapped:(UIControl *)control {
	
	ItemAnnotation *ann = (ItemAnnotation *)view.annotation;
	
	NSString *pageName = @"Timmy_Stores";
	
	NSString *name = ann.key;
	NSString *url = [NSString stringWithFormat:@"tt://home/view/%@?id=%@", [pageName substringToIndex:([pageName length]-1) ], name ];
	NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:name, @"id", nil];
	[[TTNavigator navigator] openURL:url query:query animated:YES];
		
}

- (void)mapView:(MKMapView *)mapView // there is a bug in the map view in beta 5
// that makes this method required, the map view is nto checking if we 
// respond before invoking so it blows up if we don't
didSelectSearchResult:(id)result
  userInitiated:(BOOL)userInitiated {
}

#pragma mark -
#pragma mark Location manager

/**
 Return a location manager -- create one if necessary.
 */
- (CLLocationManager *)locationManager {
	
    if (locationManager != nil) {
		return locationManager;
	}
	
	locationManager = [[CLLocationManager alloc] init];
	[locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
	[locationManager setDelegate:self];
	
	return locationManager;
}


/**
 If the location manager is generating updates, then enable the button;
 If the location manager is failing, then disable the button.
 */
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
	
	CLLocationCoordinate2D coordinate = [newLocation coordinate];
	NSNumber *latitude	= [NSNumber numberWithDouble:coordinate.latitude];
	NSNumber *longitude = [NSNumber numberWithDouble:coordinate.longitude];
	
	[self setCurrentLocation:newLocation];
	
	NSLog(@"Location = (%@, %@)", latitude, longitude);
	[[self locationManager] stopUpdatingLocation];
}


- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
	NSLog(@"Failed to get location: %@", [error localizedDescription]);
}

- (NSManagedObjectContext *)insertionContext {
	
    if (insertionContext == nil) {
        insertionContext = [[NSManagedObjectContext alloc] init];
        [insertionContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    }
    return insertionContext;
}

- (NSEntityDescription *)locEntityDescription {
	
    if (locEntityDescription == nil) {
        locEntityDescription = [[NSEntityDescription entityForName: @"Timmy_Store" inManagedObjectContext:self.insertionContext] retain];
    }
    return locEntityDescription;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
	if (persistentStoreCoordinator == nil) {
		ParabayAppDelegate *appDelegate = (ParabayAppDelegate *)[[UIApplication sharedApplication] delegate];
		persistentStoreCoordinator = appDelegate.persistentStoreCoordinator;
	}
	
	return persistentStoreCoordinator;
}

@end

// Convert our passed value to Radians
double ToRad( double nVal )
{
	return nVal * (M_PI/180);
}

/*
 Haversine Formula
 */
double calculateDistance( double nLat1, double nLon1, double nLat2, double nLon2 )
{
	double nRadius = 6371; // Earth's radius in Kilometers
	
	// Get the difference between our two points then convert the difference into radians
	double nDLat = ToRad(nLat2 - nLat1);  
	double nDLon = ToRad(nLon2 - nLon1); 
	
	nLat1 =  ToRad(nLat1);
	nLat2 =  ToRad(nLat2);
	
	double nA =	pow ( sin(nDLat/2), 2 ) +
	cos(nLat1) * cos(nLat2) * 
	pow ( sin(nDLon/2), 2 );
	
	double nC = 2 * atan2( sqrt(nA), sqrt( 1 - nA ));
	double nD = nRadius * nC;
	
	return nD; // Return our calculated distance
}

/*
 Geohash
 */
#define BASE32	"0123456789bcdefghjkmnpqrstuvwxyz"

void decode_geohash_bbox(char *geohash, double *lat, double *lon) {
	int i, j, hashlen;
	double lat_err, lon_err;
	char c, cd, mask, is_even=1;
	static char bits[] = {16,8,4,2,1};
	
	lat[0] = -90.0;  lat[1] = 90.0;
	lon[0] = -180.0; lon[1] = 180.0;
	lat_err = 90.0;  lon_err = 180.0;
	hashlen = strlen(geohash);
	
	for (i=0; i<hashlen; i++) {
		c = tolower(geohash[i]);
		cd = strchr(BASE32, c)-BASE32;
		for (j=0; j<5; j++) {
			mask = bits[j];
			if (is_even) {
				lon_err /= 2;
				lon[!(cd&mask)] = (lon[0] + lon[1])/2;
			} else {
				lat_err /= 2;
				lat[!(cd&mask)] = (lat[0] + lat[1])/2;
			}
			is_even = !is_even;
		}
	}
}

void decode_geohash(char *geohash, double *point) {
	double lat[2], lon[2];
	
	decode_geohash_bbox(geohash, lat, lon);
	
	point[0] = (lat[0] + lat[1]) / 2;
	point[1] = (lon[0] + lon[1]) / 2;
}

void encode_geohash(double latitude, double longitude, int precision, char *geohash) {
	int is_even=1, i=0;
	double lat[2], lon[2], mid;
	char bits[] = {16,8,4,2,1};
	int bit=0, ch=0;
	
	lat[0] = -90.0;  lat[1] = 90.0;
	lon[0] = -180.0; lon[1] = 180.0;
	
	while (i < precision) {
		if (is_even) {
			mid = (lon[0] + lon[1]) / 2;
			if (longitude > mid) {
				ch |= bits[bit];
				lon[0] = mid;
			} else
				lon[1] = mid;
		} else {
			mid = (lat[0] + lat[1]) / 2;
			if (latitude > mid) {
				ch |= bits[bit];
				lat[0] = mid;
			} else
				lat[1] = mid;
		}
		
		is_even = !is_even;
		if (bit < 4)
			bit++;
		else {
			geohash[i++] = BASE32[ch];
			bit = 0;
			ch = 0;
		}
	}
	geohash[i] = 0;
}

void get_neighbor(char *str, int dir, int hashlen)
{
	/* Right, Left, Top, Bottom */
	
	static char *neighbors[] = { "bc01fg45238967deuvhjyznpkmstqrwx",
		"238967debc01fg45kmstqrwxuvhjyznp",
		"p0r21436x8zb9dcf5h7kjnmqesgutwvy",
		"14365h7k9dcfesgujnmqp0r2twvyx8zb" };
	
	static char *borders[] = { "bcfguvyz", "0145hjnp", "prxz", "028b" };
	
	char last_chr, *border, *neighbor;
	int index = ( 2 * (hashlen % 2) + dir) % 4;
	neighbor = neighbors[index];
	border = borders[index];
	last_chr = str[hashlen-1];
	if (strchr(border,last_chr))
		get_neighbor(str, dir, hashlen-1);
	str[hashlen-1] = BASE32[strchr(neighbor, last_chr)-neighbor];
}
