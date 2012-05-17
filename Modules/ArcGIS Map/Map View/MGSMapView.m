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

@interface MGSMapView () <AGSMapViewTouchDelegate>
@property (nonatomic, strong) NSMutableSet *agsLayers;
@property (nonatomic, strong) NSMutableSet *layerIdentifiers;
@property (nonatomic, assign) AGSMapView *mapView;
@property (nonatomic, assign) MITLoadingActivityView *loadingView;

- (void)initView;
- (void)initBaseLayers;

- (AGSGraphicsLayer*)graphicsLayerWithName:(NSString*)layerName;
@end

@implementation MGSMapView
@synthesize mapViewDelegate = _mapViewDelegate;
@synthesize preferVectorGraphics = _preferVectorGraphics;

@synthesize agsLayers = _agsLayers;
@synthesize mapView = _mapView;
@synthesize loadingView = _loadingView;

@dynamic showUserLocation;
@dynamic layers;

+ (MGSLayerManager*)layerManagerForLayer:(MGSMapLayer*)mapLayer
                          withIdentifier:(NSString*)layerIdentifier
{
    static NSSet *layerManagers = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableSet *managers = [NSMutableSet set];
        [managers addObject:[MGSLayerManager class]];
        layerManagers = managers;
    });
    
    
}

+ (NSSet*)agsBasemapLayers
{
    NSMutableSet *layerSet = [NSMutableSet set];
    
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
        [dict setValue:@"http://ims-pub.mit.edu/ArcGIS/rest/services/mobile/WhereIs_Base_Topo_Mobile/MapServer"
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
        [dict setValue:@"http://ims-pub.mit.edu/ArcGIS/rest/services/base/WhereIs_Base_Topo/MapServer"
                forKey:@"url"];
        
        [dict setValue:@"layerIndex"
                forKey:@"0"];
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
        [dict setValue:@"http://ims-pub.mit.edu/ArcGIS/rest/services/base/WhereIs_Base/MapServer/9"
                forKey:@"url"];
        
        [dict setValue:@"layerIndex"
                forKey:@"1"];
        [dict setValue:[NSNumber numberWithBool:YES]
                forKey:@"isFeatureLayer"];
        
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
        [self initView];
        [self initBaseLayers];
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
            view.hidden = YES;
            
            [self addSubview:view];
            self.mapView = view;
        }
        
        {
            MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:mainBounds];
            loadingView.backgroundColor = [UIColor lightGrayColor];
            loadingView.usesBackgroundImage = NO;
            
            self.loadingView = loadingView;
            [self addSubview:loadingView];
        }
        
        double delayInSeconds = 2.0;
        dispatch_time_t runTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(runTime, dispatch_get_main_queue(), ^ {
            [self initBaseLayers];
        });
    }
}

- (void)initBaseLayers
{
    NSSet *layers = [MGSMapView agsBasemapLayers];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:
                                [NSSortDescriptor sortDescriptorWithKey:@"isEnabled" ascending:NO],
                                [NSSortDescriptor sortDescriptorWithKey:@"isBasemap" ascending:NO],
                                [NSSortDescriptor sortDescriptorWithKey:@"isFeatureLayer" ascending:NO],
                                [NSSortDescriptor sortDescriptorWithKey:@"layerIndex" ascending:YES],
                                nil];
    
    NSArray *defaultLayers = [layers sortedArrayUsingDescriptors:sortDescriptors];
    
    
    __block BOOL basemapLayerIsSet = NO;
    
    [defaultLayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *layerInfo = (NSDictionary*)obj;
        
        NSURL *layerURL = [NSURL URLWithString:[layerInfo valueForKey:@"url"]];
        NSString *layerIdentifier = [layerInfo objectForKey:@"layerIdentifier"];
        NSString *layerName = [layerInfo objectForKey:@"displayName"];
        
        BOOL isEnabled = [[layerInfo objectForKey:@"isEnabled"] boolValue];
        BOOL isBasemap = [[layerInfo objectForKey:@"isBasemap"] boolValue];
        BOOL isFeatureLayer = [[layerInfo objectForKey:@"isFeatureLayer"] boolValue];
        
        NSUInteger layerIndex = [[layerInfo objectForKey:@"layerIndex"] unsignedIntegerValue];
        
        if ([self.layerIdentifiers containsObject:layerIdentifier])
        {
            ELog(@"Layer identifier '%@' had a collision, skipping", layerIdentifier);
        }
        else if (isBasemap)
        {
            [self.agsLayers addObject:layerInfo];
            
            if (isEnabled && (basemapLayerIsSet == NO))
            {
                AGSTiledMapServiceLayer *serviceLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:layerURL];
                [self.mapView insertMapLayer:serviceLayer
                                    withName:layerIdentifier
                                     atIndex:0];
                [self.layerIdentifiers addObject:layerIdentifier];
                
                basemapLayerIsSet = YES;
                DLog(@"Setting baselayer id '%@' [%@]", layerIdentifier, layerName);
            }
        }
        else if (isFeatureLayer == NO)
        {
            AGSFeatureLayer *featureLayer = [AGSFeatureLayer featureServiceLayerWithURL:layerURL
                                                                                   mode:AGSFeatureLayerModeOnDemand];
            [self.mapView addMapLayer:featureLayer
                             withName:layerIdentifier];
            [self.layerIdentifiers addObject:layerIdentifier];
            DLog(@"Adding feature layer '%@' [%@] at index %d", layerIdentifier, layerName, layerIndex+1);
        }
        else
        {
            AGSTiledMapServiceLayer *serviceLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:layerURL];
            [self.mapView addMapLayer:serviceLayer
                             withName:layerIdentifier];
            [self.layerIdentifiers addObject:layerIdentifier];
            DLog(@"Adding service layer '%@' [%@] at index %d", layerIdentifier, layerName, layerIndex+1);
        }
    }];
    
    [self.loadingView removeFromSuperview];
    self.loadingView = nil;
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

- (NSArray*)layers
{
    return nil;
}


- (void)dataChangedForLayerWithIdentifier:(NSString*)layerName
{
    
}

#pragma mark - Basemap Management
- (NSSet*)availableBasemapLayers
{
    return [self.agsLayers valueForKey:@"layerIdentifier"];
}

- (NSString*)basemapLayerIdentifier
{
    return [[[self.mapView mapLayers] objectAtIndex:0] name];
}

- (void)setBasemapLayer:(NSString *)baseLayerIdentifier
{
    [self.agsLayers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSDictionary *layerInfo = obj;
        
        NSString *layerIdentifier = [layerInfo objectForKey:@"layerIdentifier"];
        (*stop) = [baseLayerIdentifier isEqualToString:layerIdentifier];
        
        if ((*stop))
        {
            
        }
    }];
}

#pragma mark - Layer Management
- (void)addLayer:(MGSMapLayer*)layer
  withIdentifier:(NSString*)layerIdentifier
{
    
}

- (BOOL)containsLayerWithIdentifier:(NSString*)layerIdentifier
{
    
}

- (void)removeLayerWithIdentifier:(NSString*)layerIdentifier
{
    
}

- (BOOL)isLayerHidden:(NSString*)layerIdentifier
{
    
}

- (void)setHidden:(BOOL)hidden forLayerIdentifier:(NSString*)layerIdentifier
{
    
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
