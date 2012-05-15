#import "MGSMapAnnotation.h"
#import "MGSMapCoordinate.h"

@implementation MGSMapAnnotation
@synthesize title = _title;
@synthesize detail = _detail;
@synthesize coordinate = _coordinate;
@synthesize annotationType = _annotationType;
@synthesize color = _color;
@synthesize icon = _icon;
@synthesize calloutImage = _calloutImage;

- (id)initWithTitle:(NSString*)title
         detailText:(NSString*)detail
       atCoordinate:(MGSMapCoordinate*)coordinate
{
    self = [super init];
    
    if (self)
    {
        self.title = title;
        self.detail = detail;
        self.coordinate = coordinate;
    }
    
    return self;
}
@end
