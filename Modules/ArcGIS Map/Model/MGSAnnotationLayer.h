#import "MGSMapLayer.h"

@interface MGSAnnotationLayer : MGSMapLayer
@property (nonatomic, strong) NSSet *annotations;

- (void)addAnnotation:(id<MGSMapAnnotation>)annotation;
- (void)deleteAnnotation:(id<MGSMapAnnotation>)annotation;
@end
