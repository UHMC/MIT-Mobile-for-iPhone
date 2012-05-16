#import "MGSMapAnnotation.h"
#import "MGSMapCoordinate.h"

@implementation MGSMapAnnotation
@synthesize coordinate = _coordinate;

@synthesize title = _title;
@synthesize detail = _detail;
@synthesize image = _image;

@synthesize annotationType = _annotationType;
@synthesize pinColor = _pinColor;
@synthesize pinIcon = _pinIcon;

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
