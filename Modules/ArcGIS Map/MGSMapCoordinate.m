#import <MapKit/MapKit.h>
#import "MGSMapCoordinate.h"
#import "MGSMapCoordinate+AGS.h"

static AGSGeometryEngine *_sharedEngine = nil;

@interface MGSMapCoordinate ()
@property (nonatomic,assign) double longitude;
@property (nonatomic,assign) double x;
@property (nonatomic,assign) double latitude;
@property (nonatomic,assign) double y;
@end

@implementation MGSMapCoordinate
@synthesize longitude = _longitude;
@synthesize latitude = _latitude;

@dynamic point;
@dynamic x, y;

+ (AGSGeometryEngine*)sharedGeometryEngine
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedEngine = [AGSGeometryEngine defaultGeometryEngine];
    });
    
    return _sharedEngine;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        self.longitude = [aDecoder decodeIntegerForKey:@"edu.mit.mobile.MITMapCoordinate.longitude"];
        self.latitude = [aDecoder decodeIntegerForKey:@"edu.mit.mobile.MITMapCoordinate.latitude"];
    }
    
    return self;
}


- (id)initWithLocation:(CLLocationCoordinate2D)location
{
    return [self initWithX:location.longitude
                         y:location.latitude];
}



- (id)initWithX:(double)x y:(double)y
{
    return [self initWithLongitude:x
                          latitude:y];
}
            
- (id)initWithLongitude:(double)longitude latitude:(double)latitude
{
    self = [super init];
    if (self)
    {
        self.longitude = longitude;
        self.latitude = latitude;
    }
    
    return self;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]])
    {
        MGSMapCoordinate *coord = (MGSMapCoordinate*)object;
        return ((self.longitude == coord.longitude) &&
                (self.latitude == coord.latitude));
    }
    
    return NO;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[MGSMapCoordinate allocWithZone:zone] initWithLongitude:self.longitude
                                                           latitude:self.latitude];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.longitude
                   forKey:@"edu.mit.mobile.MITMapCoordinate.longitude"];
    [aCoder encodeInteger:self.latitude
                   forKey:@"edu.mit.mobile.MITMapCoordinate.latitude"];
}

- (CLLocationCoordinate2D)wgs84Location
{
    return CLLocationCoordinate2DMake(self.latitude,
                                      self.longitude);
}

#pragma mark - Properties
- (void)setX:(double)x
{
    self.longitude = x;
}

- (double)x
{
    return self.longitude;
}

- (void)setY:(double)y
{
    self.latitude = y;
}

- (double)y
{
    return self.latitude;
}

- (void)setPoint:(AGSPoint *)point
{
    AGSPoint *sourcePoint = point;
    
    if ([[point spatialReference] wkid] != WKID_WGS84)
    {
        sourcePoint = (AGSPoint*)[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:point
                                                                         toSpatialReference:[AGSSpatialReference spatialReferenceWithWKID:WKID_WGS84]];
    }
    
    self.x = point.x;
    self.y = point.y;
}

- (AGSPoint*)point
{
    return [AGSPoint pointWithX:self.x
                              y:self.y
               spatialReference:[AGSSpatialReference spatialReferenceWithWKID:WKID_WGS84]];
}

@end
