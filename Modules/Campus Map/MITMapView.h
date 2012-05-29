#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "MITMapAnnotationView.h"
#import "MITMapAnnotationCalloutView.h"
#import "MITMapScrollView.h"
#import "MITProjection.h"
#import "MITMobileWebAPI.h"
#import "MITMapRoute.h"
#import "MITMapViewDelegate.h"

@class MapLevel;
@class MITMapSearchResultAnnotation;
@class MapTileOverlay;

@interface MITMapView : UIView <MKMapViewDelegate>
// message sent by MITMKProjection to let us know we can add tiles
- (void)enableProjectedFeatures;

- (void)fixateOnCampus;

@property (nonatomic, assign) id<MITMapViewDelegate> delegate;
@property BOOL stayCenteredOnUserLocation;
@property CGFloat zoomLevel;

#pragma mark MKMapView forwarding

- (void)setCenterCoordinate:(CLLocationCoordinate2D)coord animated:(BOOL)animated;
- (CGPoint)convertCoordinate:(CLLocationCoordinate2D)coordinate toPointToView:(UIView *)view;

@property MKCoordinateRegion region;
@property CLLocationCoordinate2D centerCoordinate;
@property BOOL scrollEnabled;
@property BOOL showsUserLocation;

#pragma mark Annotations
@property (nonatomic, readonly) NSArray *annotations;
@property (nonatomic, readonly) id<MKAnnotation> currentAnnotation;

// programmatically select and recenter on an annotation. Must be in our list of annotations
- (void)refreshCallout;
- (void)adjustCustomCallOut;
- (void)calloutAccessoryControlTapped:(id)sender forAnnotationView:(MITMapAnnotationView*)annotationView;
- (MKCoordinateRegion)regionForAnnotations:(NSArray *)annotations;

- (void)selectAnnotation:(id<MKAnnotation>)annotation;
- (void)selectAnnotation:(id<MKAnnotation>)annotation animated:(BOOL)animated withRecenter:(BOOL)recenter;
- (void)deselectAnnotation:(id<MKAnnotation>)annotation animated:(BOOL)animated;
- (void)addAnnotation:(id<MKAnnotation>)anAnnotation;
- (void)addAnnotations:(NSArray *)annotations;
- (void)removeAnnotations:(NSArray *)annotations;
- (void)removeAnnotation:(id<MKAnnotation>)annotation;
- (void)removeAllAnnotations:(BOOL)includeUserLocation;


#pragma mark Overlays

- (void)addRoute:(id<MITMapRoute>)route;
- (MKCoordinateRegion)regionForRoute:(id<MITMapRoute>)route;
- (void)removeAllRoutes;
- (void)removeRoute:(id<MITMapRoute>) route;

- (void)addTileOverlay;
- (void)removeTileOverlay;

@property (nonatomic, readonly) NSArray *routes;

@end
