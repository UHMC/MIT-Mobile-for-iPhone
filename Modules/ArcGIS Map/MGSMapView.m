#import "ArcGIS.h"

#import "MGSMapView.h"

#import "MGSMapLayer+Private.h"
#import "MGSMapAnnotation.h"
#import "MGSMapRoute.h"

#import "MGSMapQuery.h"
#import "MGSMapCoordinate.h"
#import "MGSAnnotationMapLayer.h"
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

- (void)loadView;

- (AGSGraphicsLayer*)graphicsLayerWithName:(NSString*)layerName;

#pragma mark - Annotation Layer Management
- (MGSAnnotationMapLayer *)annotationLayerForName:(NSString *)layerName;
- (MGSAnnotationMapLayer *)annotationLayerForName:(NSString *)layerName
                                   createIfNeeded:(BOOL)shouldCreate;
@end

@implementation MGSMapView
@synthesize mapView = _mapView;
@synthesize pendingOperations = _pendingOperations;
@synthesize mapViewDelegate = _mapViewDelegate;

@synthesize layerDelegates = _layerDelegates;
@synthesize routes = _routes;

@synthesize mapLayers = _mapLayers;

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
        [self loadView];
    }
    
    return self;
}

- (void)loadView
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

- (void)viewDidLoad
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
- (MGSAnnotationMapLayer*)annotationLayerForName:(NSString*)layerName
{
    return [self annotationLayerForName:layerName createIfNeeded:NO];
}

- (MGSAnnotationMapLayer*)annotationLayerForName:(NSString*)layerName
                                  createIfNeeded:(BOOL)shouldCreate
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

- (void)setDelegate:(id)delegate
 forAnnotationLayer:(NSString*)layerName
{
    MGSAnnotationMapLayer *annotationLayer = [self annotationLayerForName:layerName];
    
    if (annotationLayer)
    {
        annotationLayer.layerDelegate = delegate;
    }
}

- (void)setAnnotations:(NSSet*)annotations
    forAnnotationLayer:(NSString*)layerName
{
    MGSAnnotationMapLayer *annotationLayer = [self annotationLayerForName:layerName
                                                           createIfNeeded:YES];
    annotationLayer.annotations = annotations;
}

- (void)addAnnotations:(NSSet*)annotations
     toAnnotationLayer:(NSString*)layerName
{
    MGSAnnotationMapLayer *annotationLayer = [self annotationLayerForName:layerName
                                                           createIfNeeded:YES];
    annotationLayer.annotations = [annotationLayer.annotations setByAddingObjectsFromSet:annotations];
}

- (void)deleteAnnotations:(NSSet*)annotations
       forAnnotationLayer:(NSString*)layerName
{
    MGSAnnotationMapLayer *annotationLayer = [self annotationLayerForName:layerName];
    
    if (annotationLayer)
    {
        NSMutableSet *newAnnotations = [annotationLayer.annotations mutableCopy];
        [newAnnotations minusSet:annotations];
        annotationLayer.annotations = newAnnotations;
    }
}

- (void)deleteAnnotationLayer:(NSString*)layerName
{
    MGSAnnotationMapLayer *annotationLayer = [self annotationLayerForName:layerName];
    
    if (annotationLayer)
    {
        [annotationLayer removeLayer];
        [self.mapLayers removeObjectForKey:layerName];
    }
}

- (void)clearAnnotationsForLayer:(NSString*)layerName
{
    MGSAnnotationMapLayer *annotationLayer = [self annotationLayerForName:layerName];
    
    if (annotationLayer)
    {
        annotationLayer.annotations = nil;
    }
}

#pragma mark - Callouts
__TODO(Implement this method)
- (void)showCalloutForAnnotation:(id<MGSMapAnnotation>)annotation
{
    
}

__TODO(Implement this method)
- (void)showCalloutWithView:(UIView*)view forAnnotation:(id<MGSMapAnnotation>)annotation
{
    
}

__TODO(Implement this method)
- (void)hideCallout
{
    
}

#pragma mark - Routing
__TODO(Implement this method)
- (id)addRoute:(id<MGSMapRoute>)route
{
    return nil;
}

__TODO(Implement this method)
- (id)removeRoute:(id<MGSMapRoute>)route
{
    return nil;
}

__TODO(Implement this method)
- (id)hideRoute:(id<MGSMapRoute>)route
{
    return nil;
}


#pragma mark - Private Methods
- (void)setGraphic:(AGSGraphic*)graphic
     forAnnotation:(id<MGSMapAnnotation>)annotation
           inLayer:(NSString*)layerName
{
    
}

__TODO(Implement this method)
- (AGSGraphic*)graphicForAnnotation:(id<MGSMapAnnotation>)annotation
                            inLayer:(NSString*)layerName
{
    return nil;
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
