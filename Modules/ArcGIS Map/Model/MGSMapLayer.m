#import "MGSMapLayer.h"

@implementation MGSMapLayer
@synthesize name = _name;
@synthesize calloutView = _calloutView;

@synthesize annotationType = _annotationType;
@synthesize pinColor = _pinColor;
@synthesize pinIcon = _pinIcon;
@synthesize iconSize = _iconSize;

- (id)initWithName:(NSString *)name
{
    self = [super init];
    
    if (self)
    {
        self.name = name;
    }
    
    return self;
}




@end
