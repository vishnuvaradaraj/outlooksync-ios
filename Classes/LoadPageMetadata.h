//
//  LoadPageMetadata.h
//  LoginApp
//
//  Created by Vishnu Varadaraj on 16/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BaseLoadMetadataService.h"

@interface LoadPageMetadata : BaseLoadMetadataService {

	BOOL stopLoading;

}

@property (nonatomic)  BOOL stopLoading;

@end
