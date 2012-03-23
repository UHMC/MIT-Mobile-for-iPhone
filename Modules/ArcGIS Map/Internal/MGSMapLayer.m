#import "MGSMapLayer.h"
#import "MGSMapLayer+Private.h"

@implementation MGSMapLayer
@synthesize hidden = _hidden;
@synthesize layerDelegate = _layerDelegate;
@synthesize name = _name;

@synthesize mapLayer = _mapLayer;
@synthesize mapLayerView = _mapLayerView;


- (id)initWithMapLayerView:(AGSDynamicLayerView*)layerView
{
    self = [self initWithName:layerView.name];
    
    if (self)
    {
        self.mapLayerView = layerView;
        self.mapLayer = (AGSGraphicsLayer*)(layerView.agsLayer);
    }
    
    return self;
}

- (id)initWithName:(NSString *)name
{
    self = [super init];
    
    if (self)
    {
        if ([name length] == 0)
        {
            [self release];
            self = nil;
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:@"The layer's name may not be empty"
                                         userInfo:nil];
        }
        
        self.name = name;
    }
    
    return self;
}

- (BOOL)containsGraphic:(AGSGraphic*)graphic
{
    return [self.mapLayer.graphics containsObject:graphic];
}
@end