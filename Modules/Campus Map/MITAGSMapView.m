#import "MITAGSMapView.h"
#import <ArcGIS/ArcGIS.h>

static NSUInteger kWGS84Wkid = 4326;

@interface MITAGSMapView ()
@property (nonatomic,retain) AGSGeometryEngine *geometryEngine;

- (CLLocationCoordinate2D)convertPointToCLLocation:(AGSPoint*)point;
- (AGSPoint*)convertCLLocationToPoint:(CLLocationCoordinate2D)point;
@end

@implementation MITAGSMapView
@synthesize geometryEngine = _geometryEngine;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
    }
    
    return self;
}


#pragma mark - ArgGIS Conversion Methods
- (CLLocationCoordinate2D)convertPointToCLLocation:(AGSPoint*)point
{
    AGSPoint *wgs84Point = (AGSPoint*)[self.geometryEngine projectGeometry:point
                                                        toSpatialReference:[AGSSpatialReference spatialReferenceWithWKID:kWGS84Wkid]];
    
    return CLLocationCoordinate2DMake(wgs84Point.x, wgs84Point.y);
}

- (AGSPoint*)convertCLLocationToPoint:(CLLocationCoordinate2D)point
{
    AGSPoint *wgs84Point = [AGSPoint pointWithX:point.latitude
                                              y:point.longitude
                               spatialReference:[AGSSpatialReference spatialReferenceWithWKID:kWGS84Wkid]];
    
    //return (AGSPoint*)[self.geometryEngine projectGeometry:wgs84Point
	//		                toSpatialReference:self.mapView.spatialReference];
    return nil;
}

@end
