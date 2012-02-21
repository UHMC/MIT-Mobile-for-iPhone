#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class MITMapView;
@class MITMapAnnotationView;

@protocol MITMapViewDelegate<NSObject>

@optional

// MKMapView-like methods
- (void)mapView:(MITMapView *)mapView annotationSelected:(id <MKAnnotation>)annotation;
- (void)annotationCalloutDidDisappear:(MITMapView *)mapView; // TODO: this doesn't get called
- (void)mapView:(MITMapView *)mapView didUpdateUserLocation:(CLLocation *)location;
- (void)locateUserFailed:(MITMapView *)mapView;

// MKMapViewDelegate forwarding
- (MKOverlayView *)mapView:(MITMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay;
- (void)mapViewRegionWillChange:(MITMapView*)mapView;
- (void)mapViewRegionDidChange:(MITMapView*)mapView;
- (MITMapAnnotationView *)mapView:(MITMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation;
- (void)mapView:(MITMapView *)mapView annotationViewCalloutAccessoryTapped:(MITMapAnnotationView *)view;
- (void)mapView:(MITMapView *)mapView didAddAnnotationViews:(NSArray *)views;

// any touch on the map will invoke this.
- (void)mapView:(MITMapView *)mapView wasTouched:(UITouch*)touch;

@end
