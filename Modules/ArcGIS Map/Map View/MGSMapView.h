#import <UIKit/UIKit.h>

@class MGSMapCoordinate;
@class MGSMapAnnotation;
@class MGSMapQuery;
@class MGSMapLayer;

@interface MGSMapView : UIView
@property (nonatomic, strong) NSString *basemapLayer;
@property (nonatomic) BOOL showUserLocation;
@property (nonatomic) BOOL preferVectorGraphics;
@property (nonatomic,assign) id mapViewDelegate;
@property (nonatomic,readonly,strong) NSArray *layers;

- (void)dataChangedForLayerNamed:(NSString*)layerName;

#pragma mark - Basemap Management
- (NSSet*)availableBasemapLayers;
- (NSString*)basemapLayerIdentifier;
- (void)setBasemapLayer:(NSString*)baseLayerIdentifier;

#pragma mark - Layer Management
- (void)addLayer:(MGSMapLayer*)layer withIdentifier:(NSString*)layerIdentifier;
- (BOOL)containsLayerWithIdentifier:(NSString*)layerIdentifier;
- (void)removeLayerWithIdentifier:(NSString*)layerIdentifier;

- (BOOL)isLayerHidden:(NSString*)layerIdentifier;
- (void)setHidden:(BOOL)hidden forLayerIdentifier:(NSString*)layerIdentifier;

#pragma mark - Callouts
- (void)showCalloutForAnnotation:(MGSMapAnnotation*)annotation;
- (void)showCalloutWithView:(UIView*)view
              forAnnotation:(MGSMapAnnotation*)annotation;
- (void)hideCallout;

@end
