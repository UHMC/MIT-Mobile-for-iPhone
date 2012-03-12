#import "MGSMapLayer.h"

@interface MGSAnnotationMapLayer : NSObject <MGSMapLayer>
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) AGSGraphicsLayer *mapLayer;
@property (nonatomic,strong) AGSDynamicLayerView *mapLayerView;
@property (nonatomic,assign) id layerDelegate;

@property (nonatomic,strong) NSSet *annotations;

@property (nonatomic,getter=isHidden) BOOL hidden;

- (id)initWithMapLayerView:(UIView<AGSLayerView>*)layerView;
- (BOOL)containsGraphic:(AGSGraphic*)graphic;
- (void)removeLayer;
@end
