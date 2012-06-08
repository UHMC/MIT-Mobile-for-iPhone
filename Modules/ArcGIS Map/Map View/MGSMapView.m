#import <ArcGIS/ArcGIS.h>

#import "MGSMapView.h"

#import "MGSMapAnnotation.h"
#import "MGSMapQuery.h"
#import "MGSMapCoordinate.h"
#import "MGSMapCoordinate+AGS.h"
#import "MGSMapLayer.h"

#import "MITLogging.h"
#import "MITLoadingActivityView.h"

#import "MGSLayerManager.h"
#import "MGSAnnotationLayerManager.h"
#import "MGSAnnotationLayer.h"
#import "MITMobileServerConfiguration.h"

@interface MGSMapView () <AGSMapViewTouchDelegate, AGSMapViewLayerDelegate>
#pragma mark - Basemap Management (Declaration)
// Only contains layers identified as capable of being the
// basemap.
@property (nonatomic, strong) NSMutableSet *allBasemaps;

// Contains all identifiers for the default layers 
@property (nonatomic, strong) NSMutableSet *baseLayerIdentifiers;
@property (nonatomic, strong) NSDictionary *agsBaseLayers;
@property (nonatomic, strong) NSSet *initialLayerInfo;
#pragma mark -

#pragma mark - User Layer Management (Declaration)
@property (nonatomic, strong) NSMutableArray *mgsLayerIdentifiers;
@property (nonatomic, strong) NSMutableDictionary *mgsLayers;
@property (nonatomic, assign) NSUInteger indexOffset;
#pragma mark -


@property (nonatomic, assign) AGSMapView *mapView;
@property (nonatomic, assign) MITLoadingActivityView *loadingView;

- (void)initView;
- (void)initBaseLayers;

- (AGSGraphicsLayer*)graphicsLayerWithIdentifier:(NSString*)layerIdentifier;
- (MGSLayerManager*)managerForLayerWithIdentifier:(NSString*)layerIdentifier;
@end

@implementation MGSMapView
#pragma mark - Basemap/Forced Layer Management (Generation)
@synthesize activeBasemap = _activeBasemap;
@synthesize allBasemaps = _allBasemaps;
@synthesize baseLayerIdentifiers = _baseLayerIdentifiers;
@synthesize agsBaseLayers = _baseLayers;
@synthesize initialLayerInfo = _initialLayerInfo;
@dynamic availableBasemaps;
#pragma mark -

#pragma mark User Layer Management (Generation)
@synthesize mgsLayerIdentifiers = _mgsLayerIdentifiers;
@synthesize mgsLayers = _mgsLayers;
@synthesize indexOffset = _indexOffset;
@dynamic allLayers;
@dynamic visibleLayers;
#pragma mark -

@synthesize mapViewDelegate = _mapViewDelegate;
@synthesize mapView = _mapView;
@synthesize loadingView = _loadingView;

@dynamic showUserLocation;

+ (MGSLayerManager*)layerManagerForLayer:(MGSMapLayer*)mapLayer
                graphicsLayer:(AGSGraphicsLayer*)graphicsLayer
{
    MGSLayerManager *layerManager = nil;
    
    if ([MGSAnnotationLayerManager canManageLayer:mapLayer])
    {
        layerManager = [MGSAnnotationLayerManager layerManagerWithMapLayer:mapLayer
                                                             graphicsLayer:graphicsLayer];
    }
    
    return layerManager;
}

+ (NSSet*)agsBasemapLayers
{
    NSMutableSet *layerSet = [NSMutableSet set];
    NSString *apiBase = [MITMobileWebGetCurrentServerURL() absoluteString];
    
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        [dict setValue:@"com.esri.map.Base"
                forKey:@"layerIdentifier"];
        [dict setValue:@"Base (Esri)"
                forKey:@"displayName"];
        [dict setValue:@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"
                forKey:@"url"];
        
        [dict setValue:[NSNumber numberWithBool:YES]
                forKey:@"isBasemap"];
        [dict setValue:[NSNumber numberWithBool:YES]
                forKey:@"isEnabled"];
        [layerSet addObject:dict];
    }
    
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        [dict setValue:@"edu.mit.mobile.map.Base"
                forKey:@"layerIdentifier"];
        [dict setValue:@"Base (MIT)"
                forKey:@"displayName"];
        [dict setValue:[NSString stringWithFormat:@"%@/arcgis/pub/rest/services/base/WhereIs_Base/MapServer", apiBase]
                forKey:@"url"];
        
        [dict setValue:[NSNumber numberWithBool:YES]
                forKey:@"isBasemap"];
        [layerSet addObject:dict];
    }
    
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        [dict setValue:@"edu.mit.mobile.map.Campus"
                forKey:@"layerIdentifier"];
        [dict setValue:@"MIT Campus"
                forKey:@"displayName"];
        [dict setValue:[NSString stringWithFormat:@"%@/arcgis/pub/rest/services/base/WhereIs_Base/MapServer", apiBase]
                forKey:@"url"];
        
        [dict setValue:@"0"
                forKey:@"layerIndex"];
        [dict setValue:[NSNumber numberWithBool:NO]
                forKey:@"isFeatureLayer"];
        
        [layerSet addObject:dict];
    }
    
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        [dict setValue:@"edu.mit.mobile.map.Buildings"
                forKey:@"layerIdentifier"];
        [dict setValue:@"MIT Buildings"
                forKey:@"displayName"];
        [dict setValue:[NSString stringWithFormat:@"%@/arcgis/pub/rest/services/base/WhereIs_Base/MapServer/9", apiBase]
                forKey:@"url"];
        
        [dict setValue:@"1"
                forKey:@"layerIndex"];
        [dict setValue:[NSNumber numberWithBool:YES]
                forKey:@"isFeatureLayer"];
        [dict setValue:[NSNumber numberWithBool:YES]
                forKey:@"isDataOnly"];
        
        [layerSet addObject:dict];
    }
    
    return layerSet;
}

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.allBasemaps = [NSMutableSet set];
        self.baseLayerIdentifiers = [NSMutableSet set];
        self.agsBaseLayers = [NSMutableDictionary dictionary];
        self.indexOffset = 0;
        
        self.mgsLayers = [NSMutableDictionary dictionary];
        [self initView];
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

            view.touchDelegate = self;
            view.layerDelegate = self;
            view.hidden = YES;
            
            [self addSubview:view];
            self.mapView = view;
        }
        
        {
            MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:mainBounds];
            loadingView.backgroundColor = [UIColor redColor];
            loadingView.usesBackgroundImage = NO;
            
            self.loadingView = loadingView;
            [self insertSubview:loadingView
                   aboveSubview:self.mapView];
        }
        
        double delayInSeconds = 2.0;
        dispatch_time_t runTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(runTime, dispatch_get_main_queue(), ^ {
            [self initBaseLayers];
        });
    }
}

#pragma mark - Basemap Management
- (void)initBaseLayers
{
    if ([self.agsBaseLayers count] == 0)
    {
        
        NSSet *layers = [MGSMapView agsBasemapLayers];
        self.initialLayerInfo = layers;
        
        NSMutableDictionary *agsLayers = [NSMutableDictionary dictionaryWithCapacity:[layers count]];
        self.agsBaseLayers = agsLayers;
        
        NSArray *sortDescriptors = [NSArray arrayWithObjects:
                                    [NSSortDescriptor sortDescriptorWithKey:@"isEnabled" ascending:NO],
                                    [NSSortDescriptor sortDescriptorWithKey:@"isBasemap" ascending:NO],
                                    [NSSortDescriptor sortDescriptorWithKey:@"layerIndex" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"isFeatureLayer" ascending:NO],
                                    nil];
        
        NSArray *defaultLayers = [layers sortedArrayUsingDescriptors:sortDescriptors];
        
        
        [defaultLayers enumerateObjectsUsingBlock:^(NSDictionary *layerInfo, NSUInteger idx, BOOL *stop) {
            NSURL *layerURL = [NSURL URLWithString:[layerInfo valueForKey:@"url"]];
            NSString *layerIdentifier = [[layerInfo objectForKey:@"layerIdentifier"] lowercaseString];
            NSString *layerName = [layerInfo objectForKey:@"displayName"];
            
            BOOL isEnabled = [[layerInfo objectForKey:@"isEnabled"] boolValue];
            BOOL isBasemap = [[layerInfo objectForKey:@"isBasemap"] boolValue];
            BOOL isFeatureLayer = [[layerInfo objectForKey:@"isFeatureLayer"] boolValue];
            BOOL isDataOnly = [[layerInfo objectForKey:@"isDataOnly"] boolValue];
            
            
            if ([self.agsBaseLayers objectForKey:layerIdentifier] != nil)
            {
                ELog(@"Layer identifier '%@' had a collision, skipping", layerIdentifier);
            }
            else if (isBasemap)
            {
                AGSTiledMapServiceLayer *serviceLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:layerURL];
                [agsLayers setObject:serviceLayer
                              forKey:layerIdentifier];
                [self.baseLayerIdentifiers addObject:layerIdentifier];
                [self.allBasemaps addObject:layerInfo];
                
                
                if (isEnabled && ([self.activeBasemap length] == 0))
                {
                    self.activeBasemap = layerIdentifier;
                    self.indexOffset += 1;
                }
            }
            else if (isFeatureLayer)
            {
                AGSFeatureLayer *featureLayer = [AGSFeatureLayer featureServiceLayerWithURL:layerURL
                                                                                       mode:AGSFeatureLayerModeOnDemand];
                
                if (isDataOnly)
                {
                    AGSSimpleFillSymbol *symbol = [AGSSimpleFillSymbol simpleFillSymbolWithColor:[UIColor clearColor]
                                                                                    outlineColor:[UIColor colorWithRed:(115.0/255.0)
                                                                                                                 green:(38.0/255.0)
                                                                                                                  blue:0.0
                                                                                                                 alpha:1]];
                    symbol.outline.width = 0.4;
                    
                    AGSRenderer *renderer = [AGSSimpleRenderer simpleRendererWithSymbol:symbol];
                    featureLayer.renderer = renderer;
                }
                
                [agsLayers setObject:featureLayer
                              forKey:layerIdentifier];
                
                
                [self.mapView insertMapLayer:featureLayer
                                    withName:layerIdentifier
                                     atIndex:self.indexOffset];
                DLog(@"Adding feature layer '%@' [%@] at index %d", layerIdentifier, layerName, self.indexOffset);
                self.indexOffset += 1;
            }
            else
            {
                AGSTiledMapServiceLayer *serviceLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:layerURL];
                [agsLayers setObject:serviceLayer
                              forKey:layerIdentifier];
                
                [self.mapView insertMapLayer:serviceLayer
                                    withName:layerIdentifier
                                     atIndex:self.indexOffset];
                DLog(@"Adding service layer '%@' [%@] at index %d", layerIdentifier, layerName, self.indexOffset);
                self.indexOffset += 1;
            }
        }];
        
        [self.loadingView removeFromSuperview];
        self.loadingView = nil;
        self.mapView.hidden = NO;
    }
}

- (void)initTestLayer
{
    MGSAnnotationLayer *layer = [[MGSAnnotationLayer alloc] initWithName:@"Test Layer"];
    {
        MGSMapCoordinate *coordinate = [[MGSMapCoordinate alloc] initWithLongitude:-71.1046169
                                                                          latitude:42.35492042];
        MGSMapAnnotation *annotation = [[MGSMapAnnotation alloc] initWithTitle:@"W92"
                                                                    detailText:@"Test Location"
                                                                  atCoordinate:coordinate];
        
        [layer addAnnotation:annotation];
    }
    
    [self addLayer:layer
    withIdentifier:@"edu.mit.map.user.Test"];
}

- (NSSet*)availableBasemapLayers
{
    return self.baseLayerIdentifiers;
}

- (NSString*)basemapLayerIdentifier
{
    return [[[self.mapView mapLayers] objectAtIndex:0] name];
}

- (void)setActiveBasemap:(NSString *)activeBasemap
{
    if ([self.activeBasemap isEqualToString:activeBasemap] == NO)
    {
        if ([self.baseLayerIdentifiers containsObject:activeBasemap])
        {
            AGSLayer *layer = [self.agsBaseLayers objectForKey:activeBasemap];
            [self.mapView insertMapLayer:layer
                                withName:activeBasemap
                                 atIndex:0];
            
            if ([self.activeBasemap length] > 0)
            {
                [self.mapView removeMapLayerWithName:self.activeBasemap];
            }
            
            _activeBasemap = activeBasemap;
        }
    }
}


- (NSString*)nameForBasemapWithIdentifier:(NSString*)basemapIdentifier
{
    __block NSString *layerName = nil;
    
    if ([self.baseLayerIdentifiers containsObject:basemapIdentifier])
    {
        [self.initialLayerInfo enumerateObjectsUsingBlock:^(NSDictionary *layerInfo, BOOL *stop) {
            NSString *layerIdentifier = [layerInfo objectForKey:@"layerIdentifier"];
            
            if ([basemapIdentifier isEqualToString:layerIdentifier])
            {
                layerName = [layerInfo objectForKey:@"displayName"];
                (*stop) = YES;
            }
        }];
    }
    
    return layerName;
}
#pragma mark -

#pragma mark - Class Extension Methods
- (AGSGraphicsLayer*)graphicsLayerWithIdentifier:(NSString *)layerIdentifier
{
    __block AGSGraphicsLayer *layer = nil;
    
    [[self.mapView mapLayers] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        BOOL isTargetLayer = ([obj isKindOfClass:[AGSGraphicsLayer class]] &&
                              [[obj name] isEqualToString:layerIdentifier]);
        if (isTargetLayer)
        {
            layer = obj;
            (*stop) = YES;
        }
    }];
    
    return layer;
}

- (MGSLayerManager*)managerForLayerWithIdentifier:(NSString*)layerIdentifier
{
    layerIdentifier = [layerIdentifier lowercaseString];
    return [self.mgsLayers objectForKey:layerIdentifier];
}
#pragma mark -

#pragma mark - Dynamic Properties
- (void)setShowUserLocation:(BOOL)showUserLocation
{
    AGSGPS *gps = [self.mapView gps];
    if (showUserLocation && (gps.enabled == NO))
    {
        gps.autoPanMode = AGSGPSAutoPanModeDefault;
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


- (void)dataChangedForLayerWithIdentifier:(NSString*)layerIdentifier
{
    MGSLayerManager *layerManager = [self managerForLayerWithIdentifier:layerIdentifier];
    [layerManager refreshLayer];
}

#pragma mark - Layer Management
- (BOOL)addLayer:(MGSMapLayer*)layer
  withIdentifier:(NSString*)layerIdentifier
{
    return [self insertLayer:layer
                     atIndex:[self.mgsLayers count]-1
              withIdentifier:layerIdentifier];
}

- (BOOL)insertLayer:(MGSMapLayer*)layer
            atIndex:(NSUInteger)layerIndex
     withIdentifier:(NSString*)layerIdentifier
{
    MGSLayerManager *manager = [self managerForLayerWithIdentifier:layerIdentifier];
    
    if (manager != nil)
    {
        ELog(@"Layer already exists for identifier '%@'", layerIdentifier);
        return NO;
    }
    
    
    AGSGraphicsLayer *agsLayer = [AGSGraphicsLayer graphicsLayer];
    MGSLayerManager *layerManager = [MGSMapView layerManagerForLayer:layer
                                                       graphicsLayer:agsLayer];
        
    if (layerManager == nil)
    {
        return NO;
    }
    
    layerIdentifier = [layerIdentifier lowercaseString];
    layerManager.identifier = layerIdentifier;
    
    NSUInteger index = self.indexOffset + layerIndex;
    DLog(@"Adding layer '%@' at index %d", layerIdentifier, index);
    
    [self.mgsLayers setObject:layerManager
                       forKey:layerIdentifier];
    
    [self.mapView insertMapLayer:agsLayer
                        withName:layerIdentifier
                         atIndex:index];
    return YES;
}

- (MGSMapLayer*)layerWithIdentifier:(NSString*)layerIdentifier
{
    return [self managerForLayerWithIdentifier:layerIdentifier].dataLayer;
}

- (BOOL)containsLayerWithIdentifier:(NSString*)layerIdentifier
{
    return ([self managerForLayerWithIdentifier:layerIdentifier] != nil);
}

- (void)removeLayerWithIdentifier:(NSString*)layerIdentifier
{
    MGSLayerManager *manager = [self managerForLayerWithIdentifier:layerIdentifier];
    
    if (manager)
    {
        manager.graphicsView = nil;
        [self.mgsLayers removeObjectForKey:layerIdentifier];
        [self.mapView removeMapLayerWithName:layerIdentifier];
    }
}

- (BOOL)isLayerHidden:(NSString*)layerIdentifier
{
    UIView<AGSLayerView> *view = [[self.mapView mapLayerViews] objectForKey:[layerIdentifier lowercaseString]];
    return view.hidden;
}

- (void)setHidden:(BOOL)hidden forLayerIdentifier:(NSString*)layerIdentifier
{
    UIView<AGSLayerView> *view = [[self.mapView mapLayerViews] objectForKey:[layerIdentifier lowercaseString]];
    view.hidden = hidden;
}

#pragma mark - Callouts
- (void)showCalloutForAnnotation:(MGSMapAnnotation*)annotation
{
    self.mapView.callout.title = annotation.title;
    self.mapView.callout.detail = annotation.detail;
    self.mapView.callout.image = annotation.image;
    [self.mapView showCalloutAtPoint:[[annotation coordinate] agsPoint]];
}

- (void)showCalloutWithView:(UIView*)view
              forAnnotation:(MGSMapAnnotation*)annotation
{
    self.mapView.callout.customView = view;
    [self showCalloutForAnnotation:annotation];
}

- (void)hideCallout
{
    self.mapView.callout.hidden = YES;
}

#pragma mark - AGSMapViewLayerDelegate
- (void)mapViewDidLoad:(AGSMapView *)mapView
{
    NSLog(@"Basemap loaded with WKID %d", mapView.spatialReference.wkid);
    
    AGSEnvelope *maxEnvelope = [AGSEnvelope envelopeWithXmin:-7915909.671294
                                                        ymin:5212249.807534
                                                        xmax:-7912606.241692
                                                        ymax:5216998.487588
                                            spatialReference:[AGSSpatialReference spatialReferenceWithWKID:102113]];
    AGSEnvelope *projectedEnvelope = (AGSEnvelope*) [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:maxEnvelope
                                                                                            toSpatialReference:mapView.spatialReference];
    [mapView setMaxEnvelope:projectedEnvelope];
    [mapView zoomToEnvelope:projectedEnvelope
                   animated:YES];
    
    [self initTestLayer];
}

- (void)mapView:(AGSMapView *)mapView didLoadLayerForLayerView:(UIView<AGSLayerView> *)layerView
{
    NSString *identifier = layerView.agsLayer.name;
    
    MGSLayerManager *manager = [self managerForLayerWithIdentifier:identifier];
    manager.graphicsView = layerView;
}

- (void)mapView:(AGSMapView *)mapView failedLoadingLayerForLayerView:(UIView<AGSLayerView> *)layerView withError:(NSError *)error
{
    NSLog(@"Layer '%@' failed to load: %@", layerView.agsLayer.name, [error localizedDescription]);
}

#pragma mark - AGSMapViewTouchDelegate
- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics
{
    NSLog(@"Got a tap, found %d graphics", [[graphics allKeys] count]);
    NSLog(@"\tDict:\n----\n%@\n----", graphics);
    
    NSArray *geometryObjects = [graphics objectForKey:@"edu.mit.mobile.map.Buildings"];
    
    [geometryObjects enumerateObjectsUsingBlock:^(AGSGraphic *graphic, NSUInteger idx, BOOL *stop) {
        
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
