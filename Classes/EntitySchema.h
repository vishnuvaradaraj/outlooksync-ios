//
//  EntitySchema.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 19/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface EntitySchema : NSObject {
	

}

+ (NSManagedObjectModel *)managedObjectModel;
+ (NSManagedObjectModel *)managedObjectModelForVersion:(NSInteger) version;
+ (NSString *) metaDatabaseNameForVersion: (NSInteger) version;

+ (NSMutableArray *) addDefaultProperties: (NSMutableArray *) properties forVersion:(NSInteger) version;
+ (NSMutableArray *) addDefaultEntities: (NSMutableArray *) entities forVersion:(NSInteger) version;
+ (NSEntityDescription *) imageEntityForVersion:(NSInteger) version;
+ (NSEntityDescription *) locationEntityForVersion:(NSInteger) version;
+ (NSEntityDescription *) syncEntityForVersion:(NSInteger) version;

@end
