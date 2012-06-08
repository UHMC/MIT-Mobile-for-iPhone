#import <MapKit/MapKit.h>
#import "MGSMapCoordinate.h"
#import "MGSMapCoordinate+Protected.h"


@implementation MGSMapCoordinate
@synthesize longitude = _longitude;
@synthesize latitude = _latitude;

@dynamic x, y;

- (id)initWithCoder:(NSCoder *)aDecoder {
    CGFloat longitude = (CGFloat)[aDecoder decodeDoubleForKey:@"edu.mit.mobile.MITMapCoordinate.longitude"];
    CGFloat latitude = (CGFloat)[aDecoder decodeDoubleForKey:@"edu.mit.mobile.MITMapCoordinate.latitude"];

    return [self initWithLongitude:longitude
                          latitude:latitude];
}


- (id)initWithLocation:(CLLocationCoordinate2D)location {
    return [self initWithX:location.longitude
                         y:location.latitude];
}


- (id)initWithX:(double)x y:(double)y {
    return [self initWithLongitude:x
                          latitude:y];
}

- (id)initWithLongitude:(double)longitude latitude:(double)latitude {
    self = [super init];
    if (self) {
        self.longitude = longitude;
        self.latitude = latitude;
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[MGSMapCoordinate allocWithZone:zone] initWithLongitude:self.longitude
                                                           latitude:self.latitude];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeDouble:self.longitude
                   forKey:@"edu.mit.mobile.MITMapCoordinate.longitude"];
    [aCoder encodeDouble:self.latitude
                   forKey:@"edu.mit.mobile.MITMapCoordinate.latitude"];
}

- (CLLocationCoordinate2D)wgs84Location {
    return CLLocationCoordinate2DMake(self.latitude,
                                      self.longitude);
}

#pragma mark - Properties
- (void)setX:(double)x {
    self.longitude = x;
}

- (double)x {
    return self.longitude;
}

- (void)setY:(double)y {
    self.latitude = y;
}

- (double)y {
    return self.latitude;
}

#pragma mark - Overridden Methods
- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    else if ([object isKindOfClass:[self class]]) {
        return [self isEqualToCoordinate:(MGSMapCoordinate *) object];
    }
    else {
        return [super isEqual:object];
    }
}

- (BOOL)isEqualToCoordinate:(MGSMapCoordinate *)mapAnnotation {
    if (mapAnnotation == self) {
        return YES;
    }
    else {
        return ((self.longitude == mapAnnotation.longitude) &&
                (self.latitude == mapAnnotation.latitude));
    }
}

- (NSUInteger)hash {
    NSUInteger hash = 0;
    double ip, fp;

    fp = modf(self.longitude, &ip);
    hash = (NSUInteger)(fabs(fp) * ip);

    fp = modf(self.latitude, &ip);
    hash ^= (NSUInteger)(fabs(fp) * ip);

    return hash;
}
@end
