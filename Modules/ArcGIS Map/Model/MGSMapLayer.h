#import <UIKit/UIKit.h>

@class MGSMapAnnotation;
@class MGSMapCoordinate;

typedef enum {
    MGSMapAnnotationPin,
    MGSMapAnnotationSquare,
    MGSMapAnnotationCircle,
    MGSMapAnnotationHighlight,
    MGSMapAnnotationIcon
} MGSMapAnnotationType;

@protocol MGSReusableView
- (void)prepareForReuse;
- (void)prepareForDisplayWithAnnotation:(MGSMapAnnotation*)annotation;
@end

@interface MGSMapLayer : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) UIView<MGSReusableView> *calloutView;

@property (nonatomic, assign) MGSMapAnnotationType annotationType;
@property (nonatomic, strong) UIColor *pinColor;
@property (nonatomic, strong) UIImage *pinIcon;
@property (nonatomic, assign) CGSize iconSize;

- (id)initWithName:(NSString*)name;
@end
