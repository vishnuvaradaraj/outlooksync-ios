//
//  CalendarModelResponse.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 04/08/09.
//  Copyright 2009 Parabay Inc. All rights reserved.
//


#import "SearchResult.h"


@implementation SearchResult

@synthesize photoSource = _photoSource, size = _size, index = _index, caption = _caption;

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)initWithURL:(NSString*)URL smallURL:(NSString*)smallURL size:(CGSize)size {
	return [self initWithURL:URL smallURL:smallURL size:size caption:nil];
}

- (id)initWithURL:(NSString*)URL smallURL:(NSString*)smallURL size:(CGSize)size
		  caption:(NSString*)caption {
	if (self = [super init]) {
		_photoSource = nil;
		_URL = [URL copy];
		_smallURL = [smallURL copy];
		_thumbURL = [smallURL copy];
		_size = size;
		_caption = [caption copy];
		_index = NSIntegerMax;
	}
	return self;
}

- (void)dealloc {
	TT_RELEASE_SAFELY(_URL);
	TT_RELEASE_SAFELY(_smallURL);
	TT_RELEASE_SAFELY(_thumbURL);
	TT_RELEASE_SAFELY(_caption);
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTPhoto

- (NSString*)URLForVersion:(TTPhotoVersion)version {
	if (version == TTPhotoVersionLarge) {
		return _URL;
	} else if (version == TTPhotoVersionMedium) {
		return _URL;
	} else if (version == TTPhotoVersionSmall) {
		return _smallURL;
	} else if (version == TTPhotoVersionThumbnail) {
		return _thumbURL;
	} else {
		return nil;
	}
}

@end
