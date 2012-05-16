#import "MGSAnnotationLayer.h"

@interface MGSAnnotationLayer ()
@property (nonatomic, strong) NSMutableSet *mutableAnnotations;
@end

@implementation MGSAnnotationLayer
@synthesize mutableAnnotations = _mutableAnnotations;
@dynamic annotations;


#pragma mark - Dynamic Properties
- (void)setAnnotations:(NSSet *)annotations
{
    if (annotations)
    {
        self.mutableAnnotations = [NSMutableSet setWithSet:annotations];
    }
    else
    {
        self.mutableAnnotations = nil;
    }
}

- (NSSet*)annotations
{
    return self.mutableAnnotations;
}

#pragma mark - Public Methods
- (void)addAnnotation:(MGSMapAnnotation*)annotation
{
    if (annotation)
    {
        [self.mutableAnnotations addObject:annotation];
    }
}

- (void)deleteAnnotation:(MGSMapAnnotation*)annotation
{
    if (annotation)
    {
        [self.mutableAnnotations removeObject:annotation];
    }
}
@end
