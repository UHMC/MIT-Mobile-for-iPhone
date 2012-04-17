#import "MGSMapCoordinate.h"
#import "MGSMapCoordinate+AGS.h"
#import <ArcGIS/ArcGIS.h>

@interface MGSMapCoordinate ()
@property (nonatomic,strong) AGSPoint *point;
+ (AGSGeometryEngine*)sharedGeometryEngine;
@end
