//
//  CalendarModelResponse.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 04/08/09.
//  Copyright 2009 Parabay Inc. All rights reserved.
//

@class Event;

@interface Photo :  NSManagedObject  
{
}

@property (nonatomic, retain) UIImage *image;
@property (retain) NSDate *creationDate;
@property (retain) NSNumber *latitude;
@property (retain) NSNumber *longitude;
@property (retain) NSString *url;
@property (retain) NSString *tags;
@property (retain) NSNumber *uploadToServer;
@property (retain) NSNumber *cacheOnly;

@end



