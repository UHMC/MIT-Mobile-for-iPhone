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
@class MITMapView;
@class MITMapSearchResultAnnotation;
@class MapTileOverlay;


@interface MITMapView : UIView <MKMapViewDelegate> {
	BOOL _stayCenteredOnUserLocation;
	id<MITMapViewDelegate> _mapDelegate;

	NSMutableArray* _routes;
    NSMutableDictionary *_routePolylines; // kluge way to associate routes with polylines

	MITMapAnnotationCalloutView * customCallOutView;
	
	// didDeselectAnnotationView is always triggered after didSelectAnnotationView.
	// This BOOL value helps when selecting another Annotation while one is already displaying a custom callout
	BOOL addRemoveCustomAnnotationCombo;
    
    MapTileOverlay *tileOverlay;
}

// message sent by MITMKProjection to let us know we can add tiles
- (void)enableProjectedFeatures;

- (void)fixateOnCampus;

@property (nonatomic, assign) id<MITMapViewDelegate> delegate;
@property BOOL stayCenteredOnUserLocation;
@property CGFloat zoomLevel;

#pragma mark MKMapView forwarding

- (void)setCenterCoordinate:(CLLocationCoordinate2D)coord animated:(BOOL)animated;
- (CGPoint)convertCoordinate:(CLLocationCoordinate2D)coordinate toPointToView:(UIView *)view;
- (CLLocationCoordinate2D)convertPoint:(CGPoint)point toCoordinateFromView:(UIView *)view;

@property MKCoordinateRegion region;
@property CLLocationCoordinate2D centerCoordinate;
@property BOOL scrollEnabled;
@property BOOL showsUserLocation;
@property (readonly) MKUserLocation *userLocation;

#pragma mark Annotations

// programmatically select and recenter on an annotation. Must be in our list of annotations
- (void)refreshCallout;
- (void)adjustCustomCallOut;
- (void)positionAnnotationView:(MITMapAnnotationView*)annotationView;
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

@property (nonatomic, readonly) NSArray *annotations;
@property (nonatomic, readonly) id<MKAnnotation> currentAnnotation;

#pragma mark Overlays

- (void)addRoute:(id<MITMapRoute>)route;
- (MKCoordinateRegion)regionForRoute:(id<MITMapRoute>)route;
- (void)removeAllRoutes;
- (void)removeRoute:(id<MITMapRoute>) route;

- (void)addTileOverlay;
- (void)removeTileOverlay;
- (void)removeAllOverlays;

@property (nonatomic, readonly) NSArray *routes;

@end
