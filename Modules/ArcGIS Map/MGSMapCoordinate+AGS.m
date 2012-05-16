#import "MGSMapCoordinate+AGS.h"
#import "MGSMapCoordinate+Protected.h"
#import <ArcGIS/ArcGIS.h>

@implementation MGSMapCoordinate (AGS)
@dynamic agsPoint;

+ (AGSGeometryEngine*)sharedGeometryEngine
{
    return [AGSGeometryEngine defaultGeometryEngine];
}


- (void)setAgsPoint:(AGSPoint *)agsPoint
{
    AGSPoint *sourcePoint = agsPoint;
    
    if ([[agsPoint spatialReference] wkid] != WKID_WGS84)
    {
        sourcePoint = (AGSPoint*)[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:agsPoint
                                                                         toSpatialReference:[AGSSpatialReference spatialReferenceWithWKID:WKID_WGS84]];
    }
    
    self.x = sourcePoint.x;
    self.y = sourcePoint.y;
}

- (AGSPoint*)agsPoint
{
    return [AGSPoint pointWithX:self.x
                              y:self.y
               spatialReference:[AGSSpatialReference spatialReferenceWithWKID:WKID_WGS84]];
}
@end
