#import "MGSMapLayer.h"
#import <ArcGIS/ArcGIS.h>

@interface MGSMapLayer ()
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) AGSGraphicsLayer *mapLayer;
@property (nonatomic,strong) AGSDynamicLayerView *mapLayerView;

- (id)initWithMapLayerView:(AGSDynamicLayerView*)layerView;
- (BOOL)containsGraphic:(AGSGraphic*)graphic;
@end
