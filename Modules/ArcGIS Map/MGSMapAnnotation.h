#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class MGSMapCoordinate;

typedef enum {
    MITMapAnnotationPin,
    MITMapAnnotationSquare,
    MITMapAnnotationCircle,
    MITMapAnnotationHighlight,
    MITMapAnnotationCustom
} MITMapAnnotationType;

@protocol MGSMapAnnotation <NSObject>
- (NSString *)title;
- (NSString *)detail;
- (UIImage *)calloutImage;

- (UIColor *)color;
- (UIImage *)icon;
- (MGSMapCoordinate *)coordinate;
- (MITMapAnnotationType)type;

@end
