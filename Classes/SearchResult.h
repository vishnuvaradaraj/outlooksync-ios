//
//  CalendarModelResponse.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 04/08/09.
//  Copyright 2009 Parabay Inc. All rights reserved.
//

#import "Three20/Three20.h"

@interface SearchResult : NSObject<TTPhoto>
{
	id<TTPhotoSource> _photoSource;
	NSString* _thumbURL;
	NSString* _smallURL;
	NSString* _URL;
	CGSize _size;
	NSInteger _index;
	NSString* _caption;
}

- (id)initWithURL:(NSString*)URL smallURL:(NSString*)smallURL size:(CGSize)size;

- (id)initWithURL:(NSString*)URL smallURL:(NSString*)smallURL size:(CGSize)size
		  caption:(NSString*)caption;
@end
