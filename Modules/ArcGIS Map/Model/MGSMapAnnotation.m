#import "MGSMapAnnotation.h"
#import "MGSMapCoordinate.h"


@implementation MGSMapAnnotation
@synthesize coordinate = _coordinate;

@synthesize title = _title;
@synthesize detail = _detail;
@synthesize image = _image;
@synthesize userData = _userData;

- (id)initWithTitle:(NSString *)title
         detailText:(NSString *)detail
       atCoordinate:(MGSMapCoordinate *)coordinate {
    self = [super init];

    if (self) {
        self.title = title;
        self.detail = detail;
        self.coordinate = coordinate;
    }

    return self;
}

- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    else if ([object isKindOfClass:[self class]]) {
        return [self isEqualToAnnotation:(MGSMapAnnotation *) object];
    }
    else {
        return [super isEqual:object];
    }
}

- (BOOL)isEqualToAnnotation:(MGSMapAnnotation *)mapAnnotation {
    if (mapAnnotation == self) {
        return YES;
    }
    else {
        return ([self.title isEqualToString:mapAnnotation.title] &&
                [self.detail isEqualToString:mapAnnotation.detail] &&
                [self.coordinate isEqual:mapAnnotation.coordinate]);
    }
}

- (NSUInteger)hash
{
    return ([self.title hash] ^
            [self.detail hash] ^
            [self.coordinate hash]);
}

@end
