//
//  MetadataCache.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 18/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MetadataCache : NSManagedObject 

@property (nonatomic, retain) NSString *key;
@property (nonatomic, retain) NSString *value;

@end
