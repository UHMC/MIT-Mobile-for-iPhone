#import "MGSMapLayer.h"

@implementation MGSMapLayer
@synthesize name = _name;

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
