#import "MGSLayerManager.h"

@interface MGSLayerManager ()
@property (nonatomic, strong) MGSMapLayer *dataLayer;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@end

@implementation MGSLayerManager
@synthesize identifier = _identifier;
@synthesize dataLayer = _dataLayer;
@synthesize graphicsLayer = _graphicsLayer;
@synthesize graphicsView = _graphicsView;
@synthesize infoTemplateDelegate = _infoTemplateDelegate;

+ (MGSLayerManager*)layerManagerWithMapLayer:(MGSMapLayer*)layer
                               graphicsLayer:(AGSGraphicsLayer*)graphicsLayer
{
    return [[self alloc] initWithLayer:layer
                         graphicsLayer:graphicsLayer];
}

+ (BOOL)canManageLayer:(MGSMapLayer*)mapLayer
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

- (void)layerDidLoad
{
    DLog(@"Layer '%@' successfully loaded with WKID %d", self.identifier, self.graphicsLayer.spatialReference.wkid);
}

- (void)layerFailedToLoad
{
    DLog(@"Layer '%@' failed to load", self.identifier);
}
@end
