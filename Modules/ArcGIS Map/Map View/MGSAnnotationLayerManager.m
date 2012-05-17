#import "MGSAnnotationLayerManager.h"
#import "MGSAnnotationLayer.h"
#import "MGSMapAnnotation.h"

static NSString const * MGSAnnotationSetAttributeKey = @"MGSAnnotationSetAttribute";

@interface MGSAnnotationLayerManager ()

@end

@implementation MGSAnnotationLayerManager
@dynamic annotationLayer;
+ (BOOL)canManageLayer:(MGSMapLayer*)layer
{
    return [layer isKindOfClass:[MGSAnnotationLayer class]];
}

- (id)initWithLayer:(MGSMapLayer *)layer graphicsLayer:(AGSGraphicsLayer *)graphicLayer
{
    self = [super initWithLayer:layer
                  graphicsLayer:graphicLayer];
    
    if (self)
    {
        [self refreshLayer];
    }
    
    return self;
}

- (MGSAnnotationLayer*)annotationLayer
{
    return (MGSAnnotationLayer*)(self.dataLayer);
}

- (AGSRenderer *)agsRenderer
{
    AGSSymbol *symbol = nil;

    switch (self.annotationLayer.annotationType)
    {
        case MGSMapAnnotationPin:
        {
            UIImage *markerImage = [UIImage imageNamed:@"map/pin_complete"];
            AGSPictureMarkerSymbol *pictureSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:markerImage];
            pictureSymbol.yoffset = (CGFloat)(ceil(markerImage.size.height / 2.0) - 1);
            symbol = pictureSymbol;
            break;
        }

        case MGSMapAnnotationSquare:
            
        case MGSMapAnnotationCircle:
    }
}

/* TODO: Rewrite this method, it's going to be *SLOW* */
- (void)refreshLayer
{
    AGSSimpleRenderer *renderer = [AGSSimpleRenderer simpleRendererWithSymbol:nil];
    [self.graphicsLayer removeAllGraphics];

    [self.annotationLayer.annotations enumerateObjectsUsingBlock:^(MGSMapAnnotation *annotation, BOOL *stop) {
        AGSSymbol *symbol =
        AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:<#(AGSGeometry *)geometry#>
                                                       symbol:<#(AGSSymbol *)symbol#>
                                                   attributes:<#(NSMutableDictionary *)attributes#>
                                         infoTemplateDelegate:<#(id<AGSInfoTemplateDelegate>)infoTemplateDelegate#>];
    }];
}
@end
