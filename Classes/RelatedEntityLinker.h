//
//  RelatedEntityLinker.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-11-29.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Three20/Three20.h"

@interface RelatedEntityLinker : NSObject {

	NSEntityDescription *locEntityDescription;
	NSEntityDescription *imgEntityDescription;
	
    NSManagedObjectContext *insertionContext;	
}

@property (nonatomic, retain, readonly) NSEntityDescription *locEntityDescription;
@property (nonatomic, retain, readonly) NSEntityDescription *imgEntityDescription;
@property (nonatomic, retain) NSManagedObjectContext *insertionContext;

- (void) link: (NSManagedObject *)item locationField: (NSString *)location forId: (NSString *)key;
- (void) link: (NSManagedObject *)item imageField: (NSString *)propertyName forId: (NSString *)key;

@end
