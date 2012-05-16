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
@property (nonatomic, strong) MGSMapCoordinate *coordinate;

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *detail;
@property (nonatomic, strong) UIImage *image;

@property (nonatomic, assign) MITMapAnnotationType annotationType;
@property (nonatomic, strong) UIColor *pinColor;
@property (nonatomic, strong) UIImage *pinIcon;


- (id)initWithTitle:(NSString*)title
         detailText:(NSString*)detail
       atCoordinate:(MGSMapCoordinate*)coordinate;
@end
