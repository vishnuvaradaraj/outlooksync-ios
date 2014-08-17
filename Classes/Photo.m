//
//  CalendarModelResponse.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 04/08/09.
//  Copyright 2009 Parabay Inc. All rights reserved.
//

#import "Photo.h"
#import "UIImageToDataTransformer.h"

@implementation Photo 

@dynamic image, latitude, longitude, tags, url, uploadToServer, cacheOnly, creationDate;

+ (void)initialize {
	if (self == [Photo class]) {
		UIImageToDataTransformer *transformer = [[UIImageToDataTransformer alloc] init];
		[NSValueTransformer setValueTransformer:transformer forName:@"UIImageToDataTransformer"];
	}
}

@end
