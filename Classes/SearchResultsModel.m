//
//  CalendarModelResponse.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 04/08/09.
//  Copyright 2009 Parabay Inc. All rights reserved.
//


#import "SearchResultsModel.h"
#import "SearchResult.h"
#include "Globals.h"

#import "GTMNSDictionary+URLArguments.h"
#import "JSON.h"

const static NSUInteger kBatchSize = 16;   

@implementation SearchResultsModel

@synthesize source, maxPhotoIndex, numberOfPhotos, searchTerms, title, results, recordOffset;

- (id)init {
	
	if (self = [super init]) {
		results = [[NSMutableArray alloc] init];
		recordOffset = 0;
		source = SearchSourceDefault;
		searchTerms = @"";
	}
	
	return self;
}

- (void)dealloc
{
    [results release];
    [super dealloc];
}

- (NSInteger)maxPhotoIndex
{
    return ([results count] - 1);
}

- (id<TTPhoto>)photoAtIndex:(NSInteger)index 
{
    if (index < 0 || index > [self maxPhotoIndex])
        return nil;
    
    SearchResult *result = [results objectAtIndex:index];
    result.index = index;
    result.photoSource = self;
    return result;
}

- (void)load:(TTURLRequestCachePolicy)cachePolicy more:(BOOL)more
{
    if (more)
        recordOffset += kBatchSize;
    else
        [results removeAllObjects]; // Clear out data from previous request.
    
    NSString *offset = [NSString stringWithFormat:@"%lu", (unsigned long)((SearchSourceParabay == source) ? recordOffset : recordOffset+1)];
    NSString *batchSize = [NSString stringWithFormat:@"%lu", (unsigned long)kBatchSize];
    
	NSString *host;
	NSString *path;
	NSDictionary *parameters;
	if (source == SearchSourceYahoo) {
		
		host = @"http://search.yahooapis.com";
		path = @"/ImageSearchService/V1/imageSearch";
		parameters = [NSDictionary dictionaryWithObjectsAndKeys:
									searchTerms, @"query",
									@"tnZ6dEvV34HLOIpiech_XpdIJ8MvXGTaDAJvw7iBY1NzyRLNXyJEjpPh4UwBAaE-", @"appid",
									@"json", @"output",
									offset, @"start",
									batchSize, @"results",
									nil];
	}
	else {
		NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
		NSString* token = [defaults objectForKey:@"UD_TOKEN"];
		
		host = DEFAULT_HOST_ADDRESS;
		path = [NSString stringWithFormat: @"/api/files/%@", [[Globals sharedInstance] appName]];
		parameters = [NSDictionary dictionaryWithObjectsAndKeys:
									searchTerms, @"query",
									token, @"token",
									offset, @"offset",
									batchSize, @"limit",
									nil];
	}
	
    NSString *url = [host stringByAppendingFormat:@"%@?%@", path, [parameters gtm_httpArgumentsString]];
	NSLog(@"Image query: %@", url);
    TTURLRequest *request = [TTURLRequest requestWithURL:url delegate:self];
    request.cachePolicy = TTURLRequestCachePolicyNoCache;
	request.response = self;
    request.httpMethod = @"GET";
    
    // Dispatch the request.
    [request send];	
}

- (NSError*)request:(TTURLRequest*)request processResponse:(NSHTTPURLResponse*)response data:(id)data
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* token = [defaults objectForKey:@"UD_TOKEN"];
	
    NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		
    // Parse the JSON data that we retrieved from the server.
    NSDictionary *json = [responseBody JSONValue];
    
    // Drill down into the JSON object to get the parts
    // that we're actually interested in.
    NSDictionary *resultSet = [json objectForKey:@"ResultSet"];
    if (!resultSet) {
		NSLog(@"Error: No resultset for image query"); //TODO: dont leak here
		return nil;
	}
	
    numberOfPhotos = [[resultSet objectForKey:@"totalResultsAvailable"] integerValue];
	
    // Now wrap the results from the server into a domain-specific object.
    NSArray *resultsTemp = [resultSet objectForKey:@"Result"];
    for (NSDictionary *rawResult in resultsTemp) {
 
		NSString *bigImageURL = [rawResult valueForKeyPath:@"Url"];
        NSString *thumbnailURL = [rawResult valueForKeyPath:@"Thumbnail.Url"];
        CGSize bigImageSize = CGSizeMake([[rawResult objectForKey:@"Width"] intValue], 
                                         [[rawResult objectForKey:@"Height"] intValue]);

		if (SearchSourceParabay == source) {
			bigImageURL = [DEFAULT_HOST_ADDRESS stringByAppendingFormat:@"%@&token=%@", [rawResult valueForKeyPath:@"Url"], token]; 		
			thumbnailURL = [DEFAULT_HOST_ADDRESS stringByAppendingFormat:@"%@&token=%@", [rawResult valueForKeyPath:@"Thumbnail.Url"], token];
		}
		

		NSLog(@"url=%@", bigImageURL);
		
        SearchResult *result = [[[SearchResult alloc] init] autorelease];
		[result initWithURL:bigImageURL smallURL: thumbnailURL size: bigImageSize];
		
        [self.results addObject:result];
    }
	
	[responseBody release];
    return nil;
}

@end
