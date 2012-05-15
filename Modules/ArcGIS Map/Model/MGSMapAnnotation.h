#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class MGSMapCoordinate;

typedef enum {
    MITMapAnnotationPin,
    MITMapAnnotationSquare,
    MITMapAnnotationCircle,
    MITMapAnnotationHighlight,
    MITMapAnnotationIcon
} MITMapAnnotationType;

@interface MGSMapAnnotation : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *detail;
@property (nonatomic, strong) MGSMapCoordinate *coordinate;
@property (nonatomic, assign) MITMapAnnotationType annotationType;

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIImage *icon;

@property (nonatomic, strong) UIImage *calloutImage;

- (id)initWithTitle:(NSString*)title
         detailText:(NSString*)detail
       atCoordinate:(MGSMapCoordinate*)coordinate;
@end
