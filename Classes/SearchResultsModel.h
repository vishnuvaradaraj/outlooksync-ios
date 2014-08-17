//
//  CalendarModelResponse.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 04/08/09.
//  Copyright 2009 Parabay Inc. All rights reserved.
//

#import "Three20/Three20.h"

typedef enum {
    SearchSourceParabay,
    SearchSourceYahoo,
    SearchSourceDefault = SearchSourceParabay
} SearchSource;

#pragma mark -

@interface SearchResultsModel : TTURLRequestModel <TTPhotoSource, TTURLResponse> {

	SearchSource source;
	NSString* title;
	NSInteger numberOfPhotos;
	NSInteger maxPhotoIndex;
	NSString *searchTerms;                        
	NSMutableArray* results;
	NSUInteger recordOffset;
	
}

@property(nonatomic) SearchSource source;
@property(nonatomic,copy) NSString* title;
@property(nonatomic,readonly) NSInteger numberOfPhotos;
@property(nonatomic,readonly) NSInteger maxPhotoIndex;
@property (nonatomic, retain) NSString *searchTerms;                        
@property (nonatomic, retain) NSMutableArray* results;
@property(nonatomic,readonly) NSUInteger recordOffset;

- (id<TTPhoto>)photoAtIndex:(NSInteger)index;

@end
