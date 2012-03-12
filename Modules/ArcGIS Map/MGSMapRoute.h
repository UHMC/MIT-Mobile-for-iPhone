#import <UIKit/UIKit.h>

typedef enum {
    MITMapRouteLineStyleDash = 0,
    MITMapRouteLineStyleDot,
    MITMapRouteLineStyleDashDot,
    MITMapRouteLineStyleDashDotDot,
    MITMapRouteLineStyleSolid,
} MITMapRouteLineStyle;

@protocol MGSMapRoute <NSObject>
- (NSString *)routeName;
- (NSArray *)pathCoordinates;
- (NSArray *)annotations;

- (UIColor *)fillColor;
- (UIColor *)strokeColor;
- (CGFloat)lineWidth;
- (MITMapRouteLineStyle)lineStyle;

- (id)delegate;

- (NSUInteger)steps;
- (NSString*)descriptionForStep:(NSUInteger)stepIndex;
- (void)setCurrentStep:(NSUInteger)currentStep;
- (NSUInteger)currentStep;
- (NSString*)nextStep;
- (NSString*)previousStep;
@end
