
#import "Three20/Three20.h"

@interface ParabayPhotoViewController : TTViewController {
    @private
        NSManagedObject *item;
		NSString *propertyName;
        UIImageView *imageView;
}

- (id)initWithProperty:(NSString*)name query:(NSDictionary*)query;

@property(nonatomic, retain) NSManagedObject *item;
@property(nonatomic, retain) UIImageView *imageView;
@property(nonatomic, retain) NSString *propertyName;

@end
