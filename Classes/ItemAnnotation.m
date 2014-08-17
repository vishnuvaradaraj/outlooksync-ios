//
//  MapAnnotation.m
//  Test
//
//  Created by Bill Dudney on 5/15/09.
//  Copyright 2009 Gala Factory Software LLC. All rights reserved.
//
//
//  Licensed with the Apache 2.0 License
//  http://apache.org/licenses/LICENSE-2.0
//

#import "ItemAnnotation.h"


@implementation ItemAnnotation

@synthesize coordinate = _coordinate;
@synthesize title = _title;
@synthesize subtitle = _subtitle;
@synthesize key;

+ (id)annotationWithCoordinate:(CLLocationCoordinate2D)coordinate {
  return [[[[self class] alloc] initWithCoordinate:coordinate] autorelease];
}

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
  self = [super init];
  if(nil != self) {
    self.coordinate = coordinate;
  }
  return self;
}

@end
