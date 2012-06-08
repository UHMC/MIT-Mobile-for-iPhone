#import "MGSAnnotationLayer.h"

@interface MGSAnnotationLayer ()
@property (nonatomic, strong) NSMutableSet *mutableAnnotations;
@end

@implementation MGSAnnotationLayer
@synthesize mutableAnnotations = _mutableAnnotations;
@dynamic annotations;

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    if (self)
    {
        self.mutableAnnotations = [NSMutableSet set];
    }
    
    return self;
}


#pragma mark - Dynamic Properties
- (void)setAnnotations:(NSSet *)annotations
{
    [self.mutableAnnotations removeAllObjects];
    
    if (annotations)
    {
        [self.mutableAnnotations unionSet:annotations];
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
