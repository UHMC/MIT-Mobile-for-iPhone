#import "MGSAnnotationMapLayer.h"
#import "MGSMapAnnotation.h"
#import "MGSMapCoordinate.h"

@interface MGSAnnotationMapLayer ()
@property (nonatomic,strong) NSMutableDictionary *annotationGraphics;
@end

@implementation MGSAnnotationMapLayer
@synthesize name = _name;
@synthesize mapLayerView = _mapLayerView;
@synthesize mapLayer = _mapLayer;
@synthesize layerDelegate = _layerDelegate;

@synthesize annotations = _annotations;
@synthesize annotationGraphics = _annotationGraphics;

@dynamic hidden;

- (id)initWithMapLayerView:(AGSDynamicLayerView *)layerView
{
    self = [super init];
    if (self)
    {
        self.name = layerView.name;
        self.mapLayerView = layerView;
        self.mapLayer = (AGSGraphicsLayer*)[layerView agsLayer];
        //self.mapLayer.delegate = self;
        
        self.annotationGraphics = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (BOOL)containsGraphic:(AGSGraphic*)graphic
{
    return (graphic.layer && [graphic.layer isEqual:self.mapLayer]);
}

- (void)removeLayer
{
    AGSMapView *mapView = self.mapLayerView.mapView;
    
    if (mapView)
        [mapView removeMapLayerWithName:self.mapLayerView.name];
}

#pragma mark - Dynamic Properties
- (void)setHidden:(BOOL)hidden
{
    self.mapLayerView.hidden = hidden;
}

- (BOOL)isHidden
{
    return self.mapLayerView.isHidden;
}

- (void)setAnnotations:(NSSet *)annotations
{
    NSSet *activeAnnotations = self.annotations;
    _annotations = annotations;
    
    [activeAnnotations enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        if ([annotations containsObject:obj] == NO)
        {
            AGSGraphic *graphic = [self.annotationGraphics objectForKey:obj];
            [self.mapLayer removeGraphic:graphic];
            
            [self.annotationGraphics removeObjectForKey:obj];
        }
    }];
    
    [annotations enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        if ([activeAnnotations containsObject:obj] == NO)
        {
            id<MGSMapAnnotation> annotation = obj;
            UIColor *symbolColor = (annotation.color) ? annotation.color : [UIColor blueColor];
            AGSSymbol *symbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:symbolColor];
            AGSPoint *point = [AGSPoint pointWithX:annotation.coordinate.x
                                                 y:annotation.coordinate.y
                                  spatialReference:[AGSSpatialReference spatialReferenceWithWKID:102113]];
            AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:point
                                                           symbol:symbol
                                                       attributes:nil
                                             infoTemplateDelegate:nil];
            
            [self.mapLayer addGraphic:graphic];
            [self.annotationGraphics setObject:graphic
                                        forKey:annotation];
        }
    }];
    
    [self.mapLayer dataChanged];
}
@end
