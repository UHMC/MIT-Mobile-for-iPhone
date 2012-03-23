#import <UIKit/UIKit.h>

@protocol MGSMapRoute;
@protocol MGSMapCoordinate;
@protocol MGSMapAnnotation;
@class MGSMapQuery;
@class MGSRouteMapLayer;
@class MGSAnnotationMapLayer;

@interface MGSMapView : UIView
@property BOOL showUserLocation;
@property (nonatomic,assign) id mapViewDelegate;
@property (nonatomic,readonly,strong) NSArray *layers;

- (void)dataChangedForLayerNamed:(NSString*)layerName;

#pragma mark - Searching
- (id)performSearch:(MGSMapQuery*)query;

#pragma mark - Layer Management
- (BOOL)isLayerHidden:(NSString*)layerName;
- (void)setHidden:(BOOL)hidden forLayerNamed:(NSString*)layerName;
- (void)removeLayerWithName:(NSString*)layerName;

#pragma mark - Annotation Management
- (MGSAnnotationMapLayer*)annotationLayerWithName:(NSString*)layerName;
- (void)clearAnnotationsForLayer:(NSString*)layerName;
- (void)deleteAnnotationLayer:(NSString*)layerName;

#pragma mark - Callouts
- (void)showCalloutForAnnotation:(id<MGSMapAnnotation>)annotation;
- (void)showCalloutWithView:(UIView*)view forAnnotation:(id<MGSMapAnnotation>)annotation;
- (void)hideCallout;


#pragma mark - Routing
- (MGSRouteMapLayer*)routeMapLayerWithName:(NSString*)layerName;

@end
