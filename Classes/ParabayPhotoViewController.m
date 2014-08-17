
#import "ParabayPhotoViewController.h"
#import "EntityDetailsController.h"
#import "Globals.h"

@implementation ParabayPhotoViewController

@synthesize item;
@synthesize imageView;
@synthesize propertyName;

- (id)initWithProperty:(NSString*)name query:(NSDictionary*)query {
	
	if (self = [super init]) {
		self.propertyName = name;
		self.title = @"Photo";

		imageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
		imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		imageView.contentMode = UIViewContentModeScaleAspectFit;
		imageView.backgroundColor = [UIColor whiteColor];
		
		if ([ [[TTNavigator navigator] topViewController] isKindOfClass:[EntityDetailsController class]]) {
			
			EntityDetailsController *parent = (EntityDetailsController *) [[TTNavigator navigator] topViewController];
			self.item = parent.item;
		}
		
		self.view = imageView;
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];	
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger theme = [defaults integerForKey:@"theme_preference"];
	
	if (theme == 2) {
		UIApplication* app = [UIApplication sharedApplication];
		[app setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
		
		self.navigationController.navigationBar.tintColor = [UIColor 
															 blackColor]; 			
	}

    imageView.image = [[Globals sharedInstance] imageForProperty:propertyName inItem: item];	
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (void)dealloc {
    [imageView release];
    [item release];
    [super dealloc];
}


@end
