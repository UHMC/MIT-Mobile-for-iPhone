#import "MGSMapLayer.h"

@implementation MGSMapLayer
@synthesize name = _name;
@synthesize calloutView = _calloutView;

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
