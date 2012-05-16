#import "MGSMapLayer.h"

@class MGSMapAnnotation;

@interface MGSAnnotationLayer : MGSMapLayer
@property (nonatomic, strong) NSSet *annotations;

- (void)addAnnotation:(MGSMapAnnotation*)annotation;
- (void)deleteAnnotation:(MGSMapAnnotation*)annotation;
@end
