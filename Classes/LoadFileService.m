//
//  LoadFileService.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-11-29.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LoadFileService.h"
#import "ParabayAppDelegate.h"
#import "SaveService.h"
#import "Globals.h"
#import "JSON.h"

@implementation LoadFileService

@synthesize imgEntityDescription, offset;

- (id)init {
	if (self = [super init]) {
		doneNotification = ServerFileLoadedNotification;		
		offset = 0;
	}
	return self;
}

- (BOOL) sendLoadRequestWithOffset: (NSUInteger) offsetParam {
	
	self.offset = offsetParam;
	[self execute];
	
	return YES;
}

- (void)execute
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* token = [defaults objectForKey:@"UD_TOKEN"];
	
	NSString *path = [NSString stringWithFormat: @"/api/files/%@", [[Globals sharedInstance] appName]];
	NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
				  @"", @"query",
				  token, @"token",
				  offset, @"offset",
				  10, @"limit",
				  nil];
	
	[self queueRequest:path withParameters:parameters];
}

- (void)loadData:(NSDictionary *)json
{			
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* token = [defaults objectForKey:@"UD_TOKEN"];
	
	NSUInteger batchTotal = 0;	
	
	NSDictionary *resultSet = [json objectForKey:@"ResultSet"];
	NSArray *results = [resultSet objectForKey:@"Result"];
	NSUInteger count = [[resultSet objectForKey:@"totalResultsAvailable"] integerValue];
	
	for(NSDictionary *result in results) {   
		
		batchTotal++;
		
		NSString *key = [result objectForKey:@"name"];		
		
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
		
		[req release];
		
		NSUInteger isDeleted = [[result objectForKey:@"is_deleted"] integerValue];
		
		NSManagedObject *item = nil;
		if ([array count] > 0) {
			item = [array objectAtIndex:0];
			
			if (isDeleted) {
				NSLog(@"Deleting local item=%@", key);
				[insertionContext deleteObject:item];				
			}
			
		}
		
		if (!isDeleted) {
			
			if (!item) {
				item = [[NSManagedObject alloc] initWithEntity:self.imgEntityDescription insertIntoManagedObjectContext:self.insertionContext];
			}
			
			NSString *bigImageURL = [result valueForKeyPath:@"Url"];
			NSString *thumbnailURL = [result valueForKeyPath:@"Thumbnail.Url"];
			CGSize bigImageSize = CGSizeMake([[result objectForKey:@"Width"] intValue], 
											 [[result objectForKey:@"Height"] intValue]);
			
			bigImageURL = [DEFAULT_HOST_ADDRESS stringByAppendingFormat:@"%@&token=%@", [result valueForKeyPath:@"Url"], token]; 		
			thumbnailURL = [DEFAULT_HOST_ADDRESS stringByAppendingFormat:@"%@&token=%@", [result valueForKeyPath:@"Thumbnail.Url"], token];
			
			[item setValue:bigImageURL forKey:@"url"];
			[item setValue:thumbnailURL forKey:@"thumbUrl"];
			[item setValue: [NSNumber numberWithInt: bigImageSize.width] forKey:@"width"];
			[item setValue: [NSNumber numberWithInt: bigImageSize.height] forKey:@"height"];
			
			NSString *uuid = [[NSProcessInfo processInfo] globallyUniqueString];
			
			NSString *imageFilePath = [[Globals sharedInstance] imageFilePath:uuid];
			[item setValue:imageFilePath forKey:@"cacheFilePath"];
			NSLog(@"Downloading file to: %@", imageFilePath);
			
			ASIHTTPRequest *fileRequest = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: bigImageURL]];
			[fileRequest setDownloadDestinationPath: imageFilePath];
			[self.privateQueue addOperation:fileRequest];
			
			[item setValue:key forKey:@"parabay_id"];
			[item setValue:[NSDate date] forKey:@"parabay_updated"];
			[item setValue:[NSNumber numberWithInt:RecordStatusSynchronized] forKey:@"parabay_status"];
			
		}
		
	}
	
	if (batchTotal > 0) {
		NSError *saveError = nil;
		NSAssert1([insertionContext save:&saveError], @"Unhandled error saving managed object context in import location thread: %@", [saveError localizedDescription]);
	}	
	
	if (self.offset + batchTotal < count) {		
		LoadFileService *dataLoader = [[[LoadFileService alloc] init] autorelease];
		dataLoader.privateQueue = self.privateQueue;
		[dataLoader sendLoadRequestWithOffset: self.offset + batchTotal];	
	}
	else {
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithInt:0], @"status", nil];
		[self forwardResult: dict];
	}
	
}

- (NSEntityDescription *)imgEntityDescription {
	
    if (imgEntityDescription == nil) {
        imgEntityDescription = [[NSEntityDescription entityForName: @"ParabayImages" inManagedObjectContext:self.insertionContext] retain];
    }
    return imgEntityDescription;
}

@end
