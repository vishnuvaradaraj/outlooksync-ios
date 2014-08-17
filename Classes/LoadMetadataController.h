//
//  LoadMetadataController.h
//  Parabay
//
//  Created by Vishnu Varadaraj on 09-10-31.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Three20/Three20.h"
#import "Globals.h"
#import "BaseLoadMetadataService.h"

@interface LoadMetadataController : TTViewController<LoadMetadataDelegate> {

	TTActivityLabel* label;
}

@end
