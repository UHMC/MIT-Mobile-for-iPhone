#import "MGSMapLayer.h"
#import "MGSMapLayer+AGS.h"

@protocol MGSMapAnnotation;
@class MGSMapCoordinate;

@interface MGSAnnotationMapLayer : MGSMapLayer
@property (nonatomic,strong) NSSet *annotations;

- (void)addAnnotation:(id<MGSMapAnnotation>)annotation;
- (void)deleteAnnotation:(id<MGSMapAnnotation>)annotation;
- (void)deleteAllAnnotations;
@end
