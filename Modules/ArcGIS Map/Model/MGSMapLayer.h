#import <UIKit/UIKit.h>

@class MGSMapAnnotation;
@class MGSMapCoordinate;

@protocol MGSReusableView
- (void)prepareForReuse;
- (void)prepareForDisplayWithAnnotation:(MGSMapAnnotation*)annotation;
@end

@interface MGSMapLayer : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) UIView<MGSReusableView> *calloutView;

- (id)initWithName:(NSString*)name;
@end
