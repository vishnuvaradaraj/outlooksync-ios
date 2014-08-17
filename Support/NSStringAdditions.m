#import "NSStringAdditions.h"


@implementation NSString (NSStringAdditions)


- (NSString *)trimWhitespace
{
	NSMutableString *mStr = [self mutableCopy];
	CFStringTrimWhitespace((CFMutableStringRef)mStr);
	
	NSString *result = [mStr copy];
	
	[mStr release];
	return [result autorelease];
}

@end
