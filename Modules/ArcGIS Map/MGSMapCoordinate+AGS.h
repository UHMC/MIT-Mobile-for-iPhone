#import "MGSMapCoordinate.h"
#import "MGSMapCoordinate+AGS.h"
#import "ArcGIS.h"

@interface MGSMapCoordinate ()
@property (nonatomic,strong) AGSPoint *point;
+ (AGSGeometryEngine*)sharedGeometryEngine;
@end
