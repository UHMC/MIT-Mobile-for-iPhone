#import <UIKit/UIKit.h>

@protocol MGSMapRoute;
@protocol MGSMapCoordinate;
@class MGSMapQuery;

@interface MGSMapView : UIView
@property BOOL showUserLocation;
@property (nonatomic,assign) id mapViewDelegate;
@property (nonatomic,readonly,strong) NSArray *layers;

- (void)dataChangedForLayerNamed:(NSString*)layerName;

#pragma mark - Searching
- (id)performSearch:(MGSMapQuery*)query;

#pragma mark - Layer Management
- (void)setDelegate:(id)layerDelegate forLayerNamed:(NSString*)layerName;
- (BOOL)isLayerHidden:(NSString*)layerName;
- (void)setHidden:(BOOL)hidden forLayerNamed:(NSString*)layerName;
- (void)removeLayerWithName:(NSString*)layerName;

#pragma mark - Annotation Management
- (void)setDelegate:(id)delegate
 forAnnotationLayer:(NSString*)layerName;
- (void)addAnnotations:(NSSet*)annotations
     toAnnotationLayer:(NSString*)layerName;
- (void)setAnnotations:(NSSet*)annotations
    forAnnotationLayer:(NSString*)layerName;
- (void)deleteAnnotations:(NSSet*)annotations
       forAnnotationLayer:(NSString*)layerName;
- (void)clearAnnotationsForLayer:(NSString*)layerName;
- (void)deleteAnnotationLayer:(NSString*)layerName;

#pragma mark - Callouts
- (void)showCalloutForAnnotation:(id<MGSMapCoordinate>)annotation;
- (void)showCalloutWithView:(UIView*)view forAnnotation:(id<MGSMapCoordinate>)annotation;
- (void)hideCallout;

#pragma mark - Routing
@property (nonatomic,retain) id<MGSMapRoute> activeRoute;
- (id)addRoute:(id<MGSMapRoute>)route;
- (id)removeRoute:(id<MGSMapRoute>)route;
- (id)hideRoute:(id<MGSMapRoute>)route;

@end
