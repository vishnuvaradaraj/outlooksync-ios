//
//  EntitySchema.m
//  Parabay
//
//  Created by Vishnu Varadaraj on 19/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EntitySchema.h"
#import "MetadataService.h"
#import "ParabayAppDelegate.h"
#import "Globals.h"

static NSInteger currentVersion;

static NSManagedObjectModel *managedObjectModel;
static NSEntityDescription *imageEntityDescription;
static NSEntityDescription *locEntityDescription;
static NSEntityDescription *syncEntityDescription;

@implementation EntitySchema

+ (NSAttributeType) attributeTypeForServerType: (NSString *)serverType forVersion:(NSInteger) version {
	NSAttributeType attrType = NSStringAttributeType;
	
	if (NSOrderedSame == [serverType compare:@"date"]) {
		attrType = NSDateAttributeType;
	}
	else if (NSOrderedSame == [serverType compare:@"time"]) {
		attrType = NSDateAttributeType;
	}
	else if (NSOrderedSame == [serverType compare:@"integer"]) {
		attrType = NSInteger32AttributeType;
	}
	else if (NSOrderedSame == [serverType compare:@"boolean"]) {
		attrType = NSBooleanAttributeType;
	}
	else if (NSOrderedSame == [serverType compare:@"float"]) {
		attrType = NSFloatAttributeType;
	}
	
	return attrType;
}

+ (NSMutableArray *) addDefaultProperties: (NSMutableArray *) properties  forVersion:(NSInteger) version {
	
	NSAttributeDescription *attr1 = [[NSAttributeDescription alloc] init];
	[attr1 setName: @"parabay_id"];
	[attr1 setAttributeType: NSStringAttributeType];
	[attr1 setOptional:YES];
	[attr1 setUserInfo:nil];
	[properties addObject: attr1];
	
	NSAttributeDescription *attr2 = [[NSAttributeDescription alloc] init];
	[attr2 setName: @"parabay_status"];
	[attr2 setAttributeType: NSInteger32AttributeType];
	[attr2 setOptional:YES];
	[attr2 setUserInfo:nil];
	[properties addObject: attr2];
	
	NSAttributeDescription *attr3 = [[NSAttributeDescription alloc] init];
	[attr3 setName: @"parabay_updated"];
	[attr3 setAttributeType: NSDateAttributeType];
	[attr3 setOptional:YES];
	[attr3 setUserInfo:nil];
	[properties addObject: attr3];
	
	return properties;
}

+ (NSMutableArray *) addDefaultEntities: (NSMutableArray *) entities  forVersion:(NSInteger) version {
	
	NSEntityDescription *entity = [[NSEntityDescription alloc] init];
	[entity setName: @"ParabayDeletions"];
	[entity setManagedObjectClassName:@"NSManagedObject"];
	
	[entities addObject:entity];
	
	NSMutableArray *properties = [[NSMutableArray alloc] init];
	
	NSAttributeDescription *attr1 = [[NSAttributeDescription alloc] init];
	[attr1 setName: @"kind"];
	[attr1 setAttributeType: NSStringAttributeType];
	[attr1 setOptional:YES];
	[properties addObject: attr1];
	
	NSAttributeDescription *attr2 = [[NSAttributeDescription alloc] init];
	[attr2 setName: @"key"];
	[attr2 setAttributeType: NSStringAttributeType];
	[attr2 setOptional:YES];
	[properties addObject: attr2];
	
	[entity setProperties: properties];
	
	if (version > 1) {
		[entities addObject: [EntitySchema imageEntityForVersion:version]];
		[entities addObject: [EntitySchema locationEntityForVersion:version]];	
		[entities addObject: [EntitySchema syncEntityForVersion:version]];	
	}
	
	return entities;
}

+ (NSEntityDescription *) syncEntityForVersion:(NSInteger) version {
	
	if (syncEntityDescription) {
		return syncEntityDescription;
	}
	
	NSEntityDescription *entity = [[NSEntityDescription alloc] init];
	[entity setName: @"ParabaySync"];
	[entity setManagedObjectClassName:@"NSManagedObject"];
	
	NSMutableArray *properties = [[NSMutableArray alloc] init];
	
	NSAttributeDescription *attr1 = [[NSAttributeDescription alloc] init];
	[attr1 setName: @"kind"];
	[attr1 setAttributeType: NSStringAttributeType];
	[attr1 setOptional:YES];
	[properties addObject: attr1];
	
	NSAttributeDescription *attr3 = [[NSAttributeDescription alloc] init];
	[attr3 setName: @"serverSyncToken"];
	[attr3 setAttributeType: NSStringAttributeType];
	[attr3 setOptional:YES];
	[properties addObject: attr3];
			
	NSAttributeDescription *attr4 = [[NSAttributeDescription alloc] init];
	[attr4 setName: @"user"];
	[attr4 setAttributeType: NSStringAttributeType];
	[attr4 setOptional:YES];
	[properties addObject: attr4];	
	
	properties = [EntitySchema addDefaultProperties:properties forVersion:version];
	[entity setProperties: properties];
	syncEntityDescription = entity;
	
	return entity;
}

+ (NSEntityDescription *) imageEntityForVersion:(NSInteger) version {
	
	if (imageEntityDescription) {
		return imageEntityDescription;
	}
	
	NSEntityDescription *entity = [[NSEntityDescription alloc] init];
	[entity setName: @"ParabayImages"];
	[entity setManagedObjectClassName:@"NSManagedObject"];
		
	NSMutableArray *properties = [[NSMutableArray alloc] init];
	
	NSAttributeDescription *attr1 = [[NSAttributeDescription alloc] init];
	[attr1 setName: @"url"];
	[attr1 setAttributeType: NSStringAttributeType];
	[attr1 setOptional:YES];
	[properties addObject: attr1];
	
	NSAttributeDescription *attr3 = [[NSAttributeDescription alloc] init];
	[attr3 setName: @"thumbUrl"];
	[attr3 setAttributeType: NSStringAttributeType];
	[attr3 setOptional:YES];
	[properties addObject: attr3];
	
	NSAttributeDescription *attr2 = [[NSAttributeDescription alloc] init];
	[attr2 setName: @"cacheFilePath"];
	[attr2 setAttributeType: NSStringAttributeType];
	//[attr2 setValueTransformerName: @"UIImageToDataTransformer"];
	[attr2 setOptional:YES];
	[properties addObject: attr2];
	
	NSAttributeDescription *attr4 = [[NSAttributeDescription alloc] init];
	[attr4 setName: @"tags"];
	[attr4 setAttributeType: NSStringAttributeType];
	[attr4 setOptional:YES];
	[properties addObject: attr4];	
	
	NSAttributeDescription *attr5 = [[NSAttributeDescription alloc] init];
	[attr5 setName: @"description"];
	[attr5 setAttributeType: NSStringAttributeType];
	[attr5 setOptional:YES];
	[properties addObject: attr5];	
	
	NSAttributeDescription *attr6 = [[NSAttributeDescription alloc] init];
	[attr6 setName: @"uploadToServer"];
	[attr6 setAttributeType: NSBooleanAttributeType];
	[attr6 setOptional:YES];
	[attr6 setDefaultValue:[NSNumber numberWithBool:NO]];
	[properties addObject: attr6];	
	
	NSAttributeDescription *attr7 = [[NSAttributeDescription alloc] init];
	[attr7 setName: @"medium"]; 
	[attr7 setAttributeType: NSTransformableAttributeType];
	[attr7 setValueTransformerName: @"UIImageToDataTransformer"];
	[attr7 setOptional:YES];
	[properties addObject: attr7];
	
	NSAttributeDescription *attr8 = [[NSAttributeDescription alloc] init];
	[attr8 setName: @"thumbnail"]; 
	[attr8 setAttributeType: NSTransformableAttributeType];
	[attr8 setValueTransformerName: @"UIImageToDataTransformer"];
	[attr8 setOptional:YES];
	[properties addObject: attr8];
	
	NSAttributeDescription *attr9 = [[NSAttributeDescription alloc] init];
	[attr9 setName: @"isPrivate"];
	[attr9 setAttributeType: NSBooleanAttributeType];
	[attr9 setOptional:YES];
	[attr9 setDefaultValue:[NSNumber numberWithBool:NO]];
	[properties addObject: attr9];	
	
	NSAttributeDescription *attr10 = [[NSAttributeDescription alloc] init];
	[attr10 setName: @"width"];
	[attr10 setAttributeType: NSInteger32AttributeType];
	[attr10 setOptional:YES];
	[attr10 setUserInfo:nil];
	[properties addObject: attr10];

	NSAttributeDescription *attr11 = [[NSAttributeDescription alloc] init];
	[attr11 setName: @"height"];
	[attr11 setAttributeType: NSInteger32AttributeType];
	[attr11 setOptional:YES];
	[attr11 setUserInfo:nil];
	[properties addObject: attr11];
	
	properties = [EntitySchema addDefaultProperties:properties forVersion:version];
	[entity setProperties: properties];
	imageEntityDescription = entity;
	
	return entity;
}

+ (NSEntityDescription *) locationEntityForVersion:(NSInteger) version {
	
	if (locEntityDescription) {
		return locEntityDescription;
	}
	
	NSEntityDescription *entity = [[NSEntityDescription alloc] init];
	[entity setName: @"ParabayLocations"];
	[entity setManagedObjectClassName:@"NSManagedObject"];
	
	NSMutableArray *properties = [[NSMutableArray alloc] init];
	
	NSAttributeDescription *attr1 = [[NSAttributeDescription alloc] init];
	[attr1 setName: @"latitude"];
	[attr1 setAttributeType: NSDoubleAttributeType];
	[attr1 setOptional:YES];
	[properties addObject: attr1];
	
	NSAttributeDescription *attr2 = [[NSAttributeDescription alloc] init];
	[attr2 setName: @"longitude"];
	[attr2 setAttributeType: NSDoubleAttributeType];
	[attr2 setOptional:YES];
	[properties addObject: attr2];
		
	NSAttributeDescription *attr3 = [[NSAttributeDescription alloc] init];
	[attr3 setName: @"geohash"];
	[attr3 setAttributeType: NSStringAttributeType];
	[attr3 setOptional:YES];
	[properties addObject: attr3];	
		
	NSAttributeDescription *attr5 = [[NSAttributeDescription alloc] init];
	[attr5 setName: @"address"];
	[attr5 setAttributeType: NSStringAttributeType];
	[attr5 setOptional:YES];
	[properties addObject: attr5];	
	
	NSAttributeDescription *attr7 = [[NSAttributeDescription alloc] init];
	[attr7 setName: @"name"];
	[attr7 setAttributeType: NSStringAttributeType];
	[attr7 setOptional:YES];
	[properties addObject: attr7];	
	
	NSAttributeDescription *attr4 = [[NSAttributeDescription alloc] init];
	[attr4 setName: @"tags"];
	[attr4 setAttributeType: NSStringAttributeType];
	[attr4 setOptional:YES];
	[properties addObject: attr4];	
	
	NSAttributeDescription *attr6 = [[NSAttributeDescription alloc] init];
	[attr6 setName: @"uploadToServer"];
	[attr6 setAttributeType: NSBooleanAttributeType];
	[attr6 setOptional:YES];
	[attr6 setDefaultValue:[NSNumber numberWithBool:NO]];
	[properties addObject: attr6];	
		
	NSAttributeDescription *attr9 = [[NSAttributeDescription alloc] init];
	[attr9 setName: @"isPrivate"];
	[attr9 setAttributeType: NSBooleanAttributeType];
	[attr9 setOptional:YES];
	[attr9 setDefaultValue:[NSNumber numberWithBool:NO]];
	[properties addObject: attr9];	
	
	NSAttributeDescription *attr10 = [[NSAttributeDescription alloc] init];
	[attr10 setName: @"city"];
	[attr10 setAttributeType: NSStringAttributeType];
	[attr10 setOptional:YES];
	[properties addObject: attr10];	
	
	NSAttributeDescription *attr11 = [[NSAttributeDescription alloc] init];
	[attr11 setName: @"state"];
	[attr11 setAttributeType: NSStringAttributeType];
	[attr11 setOptional:YES];
	[properties addObject: attr11];	
	
	NSAttributeDescription *attr12 = [[NSAttributeDescription alloc] init];
	[attr12 setName: @"zipcode"];
	[attr12 setAttributeType: NSStringAttributeType];
	[attr12 setOptional:YES];
	[properties addObject: attr12];			

	properties = [EntitySchema addDefaultProperties:properties forVersion:version];
	[entity setProperties: properties];
	locEntityDescription = entity;
	
	return entity;
}

+ (NSString *) metaDatabaseNameForVersion: (NSInteger) version {

	NSString *dbName = kParabayMeta1;
	
	if (version > 1) {
		ParabayAppDelegate *delegate = (ParabayAppDelegate *) [[UIApplication sharedApplication] delegate];	
		dbName = [NSString stringWithFormat:@"ParabayMeta%@V%d", [delegate normalizedAppName], version];
	}
	
	return dbName;
}

+ (NSManagedObjectModel *)managedObjectModel {
	
	return [self managedObjectModelForVersion: kCurrentSchemaVersion];
}

+ (NSManagedObjectModel *)managedObjectModelForVersion:(NSInteger) version {
	
    if (managedObjectModel != nil && currentVersion == version) {
        return managedObjectModel;
    }
	
	managedObjectModel = nil;
	locEntityDescription = nil;
	imageEntityDescription = nil;
	
	managedObjectModel = [[NSManagedObjectModel alloc] init];	
	NSMutableArray *entities = [[NSMutableArray alloc] init];
	
	NSString *metaDbName = [EntitySchema metaDatabaseNameForVersion:version];
	MetadataService *metadataService = [MetadataService sharedInstanceWithDatabaseName:metaDbName];
	NSMutableArray *dataQueries = [metadataService getDataQueries];
	
	if (dataQueries) {
				
		entities = [EntitySchema addDefaultEntities:entities forVersion:version];

		for(NSDictionary *result in dataQueries) {   
			
			NSArray *entityMetadatas = [result objectForKey:@"entity_metadatas"];	
			for(NSDictionary *entityMetadata in entityMetadatas) {   
				
				NSString *entityName = [entityMetadata objectForKey:@"name"];
				
				//NSLog(@"Initializing entity type: %@", entityName);
				
				NSEntityDescription *entity = [[NSEntityDescription alloc] init];
				[entity setName: [entityName copy]];
				[entity setManagedObjectClassName:@"NSManagedObject"];
				[entity setUserInfo:[entityMetadata copy]];
				
				[entities addObject:entity];
				
				NSMutableArray *properties = [[NSMutableArray alloc] init];
				
				NSArray *entityPropertyMetadatas = [entityMetadata objectForKey:@"entity_property_metadatas"];	
				for(NSDictionary *entityPropertyMetadata in entityPropertyMetadatas) {   
					
					NSString *propertyName = [entityPropertyMetadata objectForKey:@"name"];
					NSString *propertyType = [entityPropertyMetadata objectForKey:@"type_info"];
					NSAttributeType attrType = [EntitySchema attributeTypeForServerType:propertyType forVersion: version];
					
					//NSLog(@"Initializing property: %@ (%@)", propertyName, propertyType);
					NSAttributeDescription *attr = [[NSAttributeDescription alloc] init];
					[attr setName: [propertyName copy]];
					[attr setAttributeType: attrType];
					[attr setOptional:YES];
					
					[attr setUserInfo:[entityPropertyMetadata copy] ];
					
					if (NSOrderedSame == [propertyType compare:@"image"]) {
						
						attr = nil;
						
						NSRelationshipDescription *rel = [[NSRelationshipDescription alloc] init];
						[rel setName: [propertyName copy]];
						[rel setDestinationEntity: [EntitySchema imageEntityForVersion:version]];
						[rel setMaxCount:1];
						[rel setDeleteRule:NSNullifyDeleteRule];
						[rel setOptional:YES];
						
						[rel setUserInfo:[entityPropertyMetadata copy] ];
						
						[properties addObject: rel];
						 

					}	
					else if (NSOrderedSame == [propertyType compare:@"location"]) {
						
						if (version > 1) {
							
							attr = nil;
														
							NSRelationshipDescription *rel = [[NSRelationshipDescription alloc] init];
							[rel setName: [propertyName copy] ];
							[rel setDestinationEntity: [EntitySchema locationEntityForVersion:version]];
							[rel setMaxCount:1];
							[rel setDeleteRule:NSNullifyDeleteRule];
							[rel setOptional:YES];
							
							[rel setUserInfo:[entityPropertyMetadata copy] ];
							
							[properties addObject: rel];							
						}
						
					}

					if (attr) {
						[properties addObject: attr];	
					}
				}
				
				properties = [EntitySchema addDefaultProperties:properties forVersion:version];
				[entity setProperties: properties];				
			}
					
		}
		
		[managedObjectModel setEntities: entities];
	}
		
	//save version for future queries
	currentVersion = version;
	
    return managedObjectModel;
}

@end
