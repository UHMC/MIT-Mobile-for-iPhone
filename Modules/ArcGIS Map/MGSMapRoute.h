#import <UIKit/UIKit.h>

typedef enum {
    MITMapRouteLineStyleDash = 0,
    MITMapRouteLineStyleDot,
    MITMapRouteLineStyleDashDot,
    MITMapRouteLineStyleDashDotDot,
    MITMapRouteLineStyleSolid,
} MITMapRouteLineStyle;

@protocol MGSMapRouteDelegate;

@protocol MGSMapRoute <NSObject>
- (NSString *)routeName;
- (NSArray *)pathCoordinates;
- (NSSet *)annotations;

- (UIColor *)fillColor;
- (UIColor *)strokeColor;
- (CGFloat)lineWidth;
- (MITMapRouteLineStyle)lineStyle;

- (id<MGSMapRouteDelegate>)delegate;

- (NSUInteger)steps;
- (NSString*)descriptionForStep:(NSUInteger)stepIndex;
- (void)setCurrentStep:(NSUInteger)currentStep;
- (NSUInteger)currentStep;
- (NSString*)nextStep;
- (NSString*)previousStep;
@end

@protocol MGSMapRouteDelegate <NSObject>
- (void)route:(id<MGSMapRoute>)route didLoadSteps:(NSArray*)steps;
- (void)route:(id<MGSMapRoute>)route willMoveToStep:(NSUInteger)stepIndex;
- (void)route:(id<MGSMapRoute>)route didMoveToStep:(NSUInteger)stepIndex;
@end