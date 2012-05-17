#import "MGSLayerManager.h"

@interface MGSLayerManager ()
@property (nonatomic, strong) MGSMapLayer *dataLayer;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@end

@implementation MGSLayerManager
@synthesize dataLayer = _dataLayer;
@synthesize graphicsLayer = _graphicsLayer;

+ (BOOL)canManageLayer:(MGSMapLayer*)layer
{
    return NO;
}

- (id)initWithLayer:(MGSMapLayer*)layer
      graphicsLayer:(AGSGraphicsLayer*)graphicLayer
{
    self = [super init];
    if (self)
    {
        self.dataLayer = layer;
        self.graphicsLayer = graphicLayer;
    }
    
    return self;
}

- (void)refreshLayer
{
    /* Do Nothing */
}
@end
