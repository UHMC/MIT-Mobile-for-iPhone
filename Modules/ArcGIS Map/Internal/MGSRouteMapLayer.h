#import "MGSMapLayer.h"

@protocol MGSMapRoute;
@class MGSMapCoordinate;

@interface MGSRouteMapLayer : NSObject <MGSMapLayer>
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) AGSGraphicsLayer *mapLayer;
@property (nonatomic,strong) AGSDynamicLayerView *mapLayerView;
@property (nonatomic,assign) id layerDelegate;

@property (nonatomic,strong) NSArray *routes;
@property (nonatomic,strong) id<MGSMapRoute> activeRoute;
@property (nonatomic,readonly,strong) NSArray *steps;

@property (nonatomic,readonly) NSUInteger stepIndex;
@property (nonatomic,readonly) NSString *stepDescription;

@property (nonatomic,getter=isHidden) BOOL hidden;

@end
