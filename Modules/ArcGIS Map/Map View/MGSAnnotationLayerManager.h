#import "MGSLayerManager.h"

extern NSString const *MGSAnnotationAttributeKey;

@class MGSAnnotationLayer;

@interface MGSAnnotationLayerManager : MGSLayerManager
@property (nonatomic, readonly) MGSAnnotationLayer *annotationLayer;
@end
