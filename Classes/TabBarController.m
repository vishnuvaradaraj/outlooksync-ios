#import "TabBarController.h"

@implementation TabBarController

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIViewController

- (void)viewDidLoad {
	
  [self setTabURLs:[NSArray arrayWithObjects:	@"tt://home/menu/root",
												@"tt://home/about",
												nil]];
}

@end
