#import <ArcGIS/ArcGIS.h>

#import "MGSMapView.h"

#import "MGSMapLayer+AGS.h"
#import "MGSAnnotationMapLayer.h"

#import "MGSMapAnnotation.h"
#import "MGSMapRoute.h"

#import "MGSMapQuery.h"
#import "MGSMapCoordinate.h"
#import "MGSMapCoordinate+AGS.h"

#import "MITLogging.h"

static NSString *MITBaseMapURL = @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer";
static NSString *MITMapServicesURL = @"http://ims-pub.mit.edu/ArcGIS/rest/services/";
static NSString *MITCampusMapPath = @"base/WhereIs_Base_Topo/MapServer";
static NSString *MITBuildingsMapPath = @"base/WhereIs_Base/MapServer/9";

@interface MGSMapView () <AGSMapViewTouchDelegate>
@property (nonatomic,assign) AGSMapView *mapView;
@property (nonatomic,strong) NSMutableDictionary *pendingOperations;

@property (nonatomic,strong) NSSet *lockedLayers;

@property (nonatomic,strong) NSMutableDictionary *mapLayers;
@property (nonatomic,strong) NSMutableArray *orderedLayers;

@property (nonatomic,strong) NSMutableDictionary *layerDelegates;
@property (nonatomic,strong) NSMutableSet *routes;

- (void)initView;
- (void)initLayers;

- (AGSGraphicsLayer*)graphicsLayerWithName:(NSString*)layerName;
@end

@implementation MGSMapView
@synthesize mapView = _mapView;
@synthesize pendingOperations = _pendingOperations;
@synthesize mapViewDelegate = _mapViewDelegate;

@synthesize layerDelegates = _layerDelegates;
@synthesize routes = _routes;

@synthesize mapLayers = _mapLayers;

@synthesize orderedLayers = _orderedLayers;
@synthesize lockedLayers = _lockedLayers;

@dynamic showUserLocation;
@dynamic layers;

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        [self initView];
        [self initLayers];
    }
    
    return self;
}

- (void)initView
{
    if (self.mapView == nil)
    {
        CGRect mainBounds = self.bounds;
        
        {
            AGSMapView* view = [[AGSMapView alloc] initWithFrame:mainBounds];
            view.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
            
            AGSEnvelope *maxEnvelope = [AGSEnvelope envelopeWithXmin:-7915909.671294
                                                                ymin:5212249.807534
                                                                xmax:-7912606.241692
                                                                ymax:5216998.487588
                                                    spatialReference:[AGSSpatialReference spatialReferenceWithWKID:102113]];
            [view setMaxEnvelope:maxEnvelope];
            [view zoomToEnvelope:maxEnvelope
                        animated:NO];
            view.touchDelegate = self;
            [self addSubview:view];
            self.mapView = view;
        }
    }
}

- (void)initLayers
{
    if (self.lockedLayers == nil)
    {
        NSMutableSet *defaultLayers = [NSMutableSet set];
        {
            NSString *layerId = @"edu.mit.mobile.map.Base";
            NSURL *basemapURL = [NSURL URLWithString:MITBaseMapURL];
            AGSTiledMapServiceLayer *basemap = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:basemapURL];
            [self.mapView addMapLayer:basemap
                             withName:layerId];
            [defaultLayers addObject:layerId];
        }
        
        NSURL *mitServicesURL = [NSURL URLWithString:MITMapServicesURL];
        {
            NSString *layerId = @"edu.mit.mobile.map.MIT";
            NSURL *mitBasemapURL = [NSURL URLWithString:MITCampusMapPath
                                          relativeToURL:mitServicesURL];
            AGSTiledMapServiceLayer *mitMap = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mitBasemapURL];
            [self.mapView addMapLayer:mitMap
                             withName:layerId];
            [defaultLayers addObject:layerId];
        }
        
        {
            NSString *layerId = @"edu.mit.mobile.map.Buildings";
            NSURL *mitBasemapURL = [NSURL URLWithString:MITBuildingsMapPath
                                          relativeToURL:mitServicesURL];
            AGSFeatureLayer *mitMap = [AGSFeatureLayer featureServiceLayerWithURL:mitBasemapURL
                                                                             mode:AGSFeatureLayerModeOnDemand];
            AGSSymbol *symbol = [AGSSimpleFillSymbol simpleFillSymbolWithColor:[UIColor clearColor]
                                                                  outlineColor:[UIColor clearColor]];
            AGSRenderer *renderer = [AGSSimpleRenderer simpleRendererWithSymbol:symbol];
            mitMap.renderer = renderer;
            [self.mapView addMapLayer:mitMap
                             withName:layerId];
            [defaultLayers addObject:layerId];
        }
        
        self.lockedLayers = [NSSet setWithSet:defaultLayers];
    }
}

#pragma mark - Private Methods
- (AGSGraphicsLayer*)graphicsLayerWithName:(NSString *)layerName
{
    __block AGSGraphicsLayer *layer = nil;
    
    [[self.mapView mapLayers] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        BOOL isTargetLayer = ([obj isKindOfClass:[AGSGraphicsLayer class]] &&
                              [[obj name] isEqualToString:layerName]);
        if (isTargetLayer)
        {
            layer = obj;
            (*stop) = YES;
        }
    }];
    
    return layer;
}

#pragma mark - Dynamic Properties
- (void)setShowUserLocation:(BOOL)showUserLocation
{
    AGSGPS *gps = [self.mapView gps];
    if (showUserLocation && (gps.enabled == NO))
    {
        gps.autoPanMode = AGSGPSAutoPanModeOff;
        [gps start];
    }
    else if ((showUserLocation == NO) && gps.enabled)
    {
        [gps stop];
    }
}

- (BOOL)showUserLocation
{
    return [[self.mapView gps] enabled];
}

- (NSArray*)layers
{
    return [NSArray arrayWithArray:self.orderedLayers];
}

#pragma mark -
__TODO(Implement this method)
- (void)dataChangedForLayerNamed:(NSString*)layerName
{
    
}

#pragma mark - Searching
__TODO(Implement this method)
- (id)performSearch:(MGSMapQuery*)query
{
    return nil;
}

#pragma mark - Layer Management
- (void)setDelegate:(id)layerDelegate forLayerNamed:(NSString*)layerName
{
    [self.layerDelegates setObject:layerDelegate
                            forKey:layerName];
}

- (BOOL)isLayerHidden:(NSString*)layerName
{
    return [[[self.mapLayers objectForKey:layerName] mapLayerView] isHidden];
}

- (void)setHidden:(BOOL)hidden forLayerNamed:(NSString*)layerName
{
    [[[self.mapLayers objectForKey:layerName] mapLayerView] setHidden:hidden];
}


- (MGSMapLayer*)layerForName:(NSString *)layerName
{
    return [self.mapLayers objectForKey:layerName];
}

- (void)setLayer:(MGSMapLayer*)layer forName:(NSString*)layerName
{
    if ([self layerForName:layerName])
    {
        [self removeLayerWithName:layerName];
    }

    [self.mapLayers setObject:layerName
                       forKey:layer];
    [self.orderedLayers addObject:layerName];
}

- (void)removeLayerWithName:(NSString*)layerName
{
    MGSMapLayer* layer = [self layerForName:layerName];
    
    if (layer)
    {
        [self.mapView removeMapLayerWithName:layer.name];
        layer.mapLayerView = nil;
        [self.orderedLayers removeObject:layerName];
        [self.mapLayers removeObjectForKey:layerName];
    }
}

#pragma mark - Annotation Management
- (MGSAnnotationMapLayer*)annotationLayerWithName:(NSString*)layerName
{
    return [self annotationLayerWithName:layerName
                       shouldCreateLayer:NO];
}

- (MGSAnnotationMapLayer*)annotationLayerWithName:(NSString*)layerName
                                shouldCreateLayer:(BOOL)shouldCreate
{
    MGSMapLayer* mapLayer = [self layerForName:layerName];
    
    if (mapLayer && ([mapLayer isKindOfClass:[MGSAnnotationMapLayer class]] == NO))
    {
        return nil;
    }
    
    MGSAnnotationMapLayer *annotationLayer = (MGSAnnotationMapLayer*)mapLayer;
    
    if (shouldCreate && (annotationLayer == nil))
    {
        AGSGraphicsLayer *layer = [AGSGraphicsLayer graphicsLayer];
        AGSDynamicLayerView *view = (AGSDynamicLayerView*)[self.mapView addMapLayer:layer
                                                                           withName:layerName];
        MGSAnnotationMapLayer *layerWrapper = [[MGSAnnotationMapLayer alloc] initWithMapLayerView:view];
        [self.mapLayers setObject:layerWrapper
                           forKey:layerName];
        [self.orderedLayers addObject:layerName];
        annotationLayer = layerWrapper;
    }
    
    return annotationLayer;
}

- (void)removeAnnotationLayer:(NSString*)layerName
{
    MGSAnnotationMapLayer *annotationLayer = [self annotationLayerWithName:layerName];
    
    if (annotationLayer)
    {
        [self.mapLayers removeObjectForKey:layerName];
    }
}

- (void)clearAnnotationsForLayer:(NSString*)layerName
{
    MGSAnnotationMapLayer *annotationLayer = [self annotationLayerWithName:layerName];
    
    if (annotationLayer)
    {
        annotationLayer.annotations = nil;
    }
}

#pragma mark - Callouts
- (void)showCalloutForAnnotation:(id<MGSMapAnnotation>)annotation
{
    self.mapView.callout.title = [annotation title];
    self.mapView.callout.detail = [annotation detail];
    [self.mapView showCalloutAtPoint:[[annotation coordinate] point]];
}

- (void)showCalloutWithView:(UIView*)view forAnnotation:(id<MGSMapAnnotation>)annotation
{
    self.mapView.callout.customView = view;
    [self showCalloutForAnnotation:annotation];
}

__TODO("Implement this method")
- (void)hideCallout
{
    
}

#pragma mark - AGSMapViewTouchDelegate
- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics
{
    NSLog(@"Got a tap, found %d graphics", [[graphics allKeys] count]);
    NSLog(@"\tDict:\n----\n%@\n----", graphics);

    NSArray *geometryObjects = [graphics objectForKey:@"edu.mit.mobile.map.Buildings"];
    
    [geometryObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        AGSGraphic *graphic = obj;
        
        if ([graphic.geometry.envelope containsPoint:mappoint])
        {
            AGSFeatureLayer *featureLayer = (AGSFeatureLayer*)[graphic layer];
            NSString *title = [graphic.attributes objectForKey:featureLayer.displayField];
            self.mapView.callout.title = title;
            [self.mapView showCalloutAtPoint:graphic.geometry.envelope.center
                                  forGraphic:graphic
                                    animated:YES];
        }
    }];
}
@end
