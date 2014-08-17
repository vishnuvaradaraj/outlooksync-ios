//
//  RelatedEntityLinker.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-11-29.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "RelatedEntityLinker.h"
#import "Three20/Three20.h"

@implementation RelatedEntityLinker

@synthesize locEntityDescription, imgEntityDescription, insertionContext;

- (void) link: (NSManagedObject *)item locationField: (NSString *)propertyName forId: (NSString *)key {

	NSLog(@"Linking location %@-> %@", propertyName, key);
		
	NSFetchRequest *req = [[NSFetchRequest alloc] init];
	[req setEntity:self.locEntityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"parabay_id = %@", key];
	[req setPredicate:predicate];
	
	NSError *dataError = nil;
	NSArray *array = [self.insertionContext executeFetchRequest:req error:&dataError];
	if ((dataError != nil) || (array == nil)) {
		NSLog(@"Error while fetching\n%@",
			  ([dataError localizedDescription] != nil)
			  ? [dataError localizedDescription] : @"Unknown Error");
	}
	
	NSManagedObject *locItem = nil;
	if ([array count] > 0) {
		locItem = [array objectAtIndex:0];	
		[item setValue: locItem forKey: propertyName];		
	}
	
	[req release];
	
}

- (void) link: (NSManagedObject *)item imageField: (NSString *)propertyName forId: (NSString *)key {
	
	NSLog(@"Linking image %@-> %@", propertyName, key);
	
	NSFetchRequest *req = [[NSFetchRequest alloc] init];
	[req setEntity:self.imgEntityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"parabay_id = %@", key];
	[req setPredicate:predicate];
	
	NSError *dataError = nil;
	NSArray *array = [self.insertionContext executeFetchRequest:req error:&dataError];
	if ((dataError != nil) || (array == nil)) {
		NSLog(@"Error while fetching\n%@",
			  ([dataError localizedDescription] != nil)
			  ? [dataError localizedDescription] : @"Unknown Error");
	}
	
	NSManagedObject *imgItem = nil;
	if ([array count] > 0) {
		imgItem = [array objectAtIndex:0];	
		[item setValue: imgItem forKey: propertyName];		
	}
	
	[req release];
	
}

- (NSEntityDescription *)imgEntityDescription {
	
    if (imgEntityDescription == nil) {
        imgEntityDescription = [[NSEntityDescription entityForName: @"ParabayImages" inManagedObjectContext:self.insertionContext] retain];
    }
    return imgEntityDescription;
}

- (NSEntityDescription *)locEntityDescription {
	
    if (locEntityDescription == nil) {
        locEntityDescription = [[NSEntityDescription entityForName: @"ParabayLocations" inManagedObjectContext:self.insertionContext] retain];
    }
    return locEntityDescription;
}

@end
