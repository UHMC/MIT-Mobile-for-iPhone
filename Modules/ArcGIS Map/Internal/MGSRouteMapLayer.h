#import "MGSMapLayer.h"
#import "MGSMapRoute.h"

@class MGSMapCoordinate;

@interface MGSRouteMapLayer : MGSMapLayer
@property (nonatomic,strong) NSArray *possibleRoutes;
@property (nonatomic,strong) id<MGSMapRoute> activeRoute;

@property (nonatomic,readonly,strong) NSArray *steps;
@property (nonatomic,readonly,strong) NSString *currentStepDescription;
@property (nonatomic,readonly) NSUInteger currentStepIndex;

- (void)advanceToStep:(NSUInteger)stepIndex;
- (void)nextStep;
- (void)previousStep;
@end
