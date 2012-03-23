#import <MapKit/MapKit.h>
#import "MGSMapCoordinate.h"
#import "ArcGIS.h"

typedef enum {
    MITCoordinateWGS84 = 4326,
    MITCoordinateWebMercator = 102113
} MITCoordinateSystem;

static AGSGeometryEngine *_sharedEngine = nil;

@interface MGSMapCoordinate ()
@property (nonatomic,strong) AGSPoint *point;
@property (nonatomic,assign) double longitude;
@property (nonatomic,assign) double x;
@property (nonatomic,assign) double latitude;
@property (nonatomic,assign) double y;

+ (AGSGeometryEngine*)sharedGeometryEngine;
+ (MGSMapCoordinate*)projectCoordinate:(MGSMapCoordinate*)coordinate toCoordinateSystem:(MITCoordinateSystem)projection;
@end

@implementation MGSMapCoordinate
@dynamic longitude, latitude;
@dynamic x, y;

+ (AGSGeometryEngine*)sharedGeometryEngine
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedEngine = [AGSGeometryEngine defaultGeometryEngine];
    });
    
    return _sharedEngine;
}

+ (MGSMapCoordinate*)projectCoordinate:(MGSMapCoordinate*)coordinate
                  fromCoordinateSystem:(MITCoordinateSystem)srcProjection
                    toCoordinateSystem:(MITCoordinateSystem)projection
{
    AGSPoint *srcPoint = [AGSPoint pointWithX:coordinate.x
                                            y:coordinate.y
                             spatialReference:[AGSSpatialReference spatialReferenceWithWKID:srcProjection]];
    AGSPoint *projectedPoint = (AGSPoint*)[[self sharedGeometryEngine] projectGeometry:srcPoint
                                                                    toSpatialReference:[AGSSpatialReference spatialReferenceWithWKID:projection]];
    
    MGSMapCoordinate *coord = [[MGSMapCoordinate alloc] initWithX:projectedPoint.x
                                                                y:projectedPoint.y];
    return [coord autorelease];
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
    AGSPoint *srcPoint = [AGSPoint pointWithX:location.longitude
                                            y:location.latitude
                             spatialReference:[AGSSpatialReference spatialReferenceWithWKID:MITCoordinateWGS84]];
    AGSPoint *projectedPoint = (AGSPoint*)[[MGSMapCoordinate sharedGeometryEngine] projectGeometry:srcPoint
                                                                                toSpatialReference:[AGSSpatialReference spatialReferenceWithWKID:MITCoordinateWebMercator]];
    return [self initWithX:projectedPoint.x
                         y:projectedPoint.y];
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
    MGSMapCoordinate *projectedCoord = [MGSMapCoordinate projectCoordinate:self
                                                      fromCoordinateSystem:MITCoordinateWebMercator
                                                        toCoordinateSystem:MITCoordinateWGS84];
    return CLLocationCoordinate2DMake(projectedCoord.latitude,
                                      projectedCoord.longitude);
}

#pragma mark - Dynamic Properties
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

@end
