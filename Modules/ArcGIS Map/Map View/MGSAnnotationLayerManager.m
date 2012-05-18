#import "MGSAnnotationLayerManager.h"
#import "MGSAnnotationLayer.h"
#import "MGSMapAnnotation.h"


static NSString const *MGSAnnotationSetAttributeKey = @"MGSAnnotationSetAttribute";

@interface MGSAnnotationLayerManager ()
- (AGSRenderer *)agsRenderer;
@end

@implementation MGSAnnotationLayerManager
@dynamic annotationLayer;

+ (BOOL)canManageLayer:(MGSMapLayer *)layer {
    return [layer isKindOfClass:[MGSAnnotationLayer class]];
}

- (id)initWithLayer:(MGSMapLayer *)layer graphicsLayer:(AGSGraphicsLayer *)graphicLayer {
    self = [super initWithLayer:layer
                  graphicsLayer:graphicLayer];

    if (self) {
        [self refreshLayer];
    }

    return self;
}

- (MGSAnnotationLayer *)annotationLayer {
    return (MGSAnnotationLayer *) (self.dataLayer);
}

- (AGSRenderer *)agsRenderer {
    AGSSymbol *symbol = nil;

    UIColor *markerColor = (self.dataLayer.pinColor ?
                            self.dataLayer.pinColor :
                            [UIColor blueColor]);

    CGFloat markerSize = MAX(self.dataLayer.iconSize.height, self.dataLayer.iconSize.width);

    // Don't use a zero check here, floats lie
    markerSize = (markerSize < 1 ? 32.0 : markerSize);

    switch (self.annotationLayer.annotationType) {
        case MGSMapAnnotationPin: {
            UIImage *markerImage = [UIImage imageNamed:@"map/pin_complete"];
            AGSPictureMarkerSymbol *pictureSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:markerImage];
            pictureSymbol.yoffset = (CGFloat) (ceil(markerImage.size.height / 2.0) - 1);
            symbol = pictureSymbol;
            break;
        }

        case MGSMapAnnotationSquare: {
            AGSSimpleMarkerSymbolStyle symbolStyle = AGSSimpleMarkerSymbolStyleSquare;
            AGSSimpleMarkerSymbol *markerSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:markerColor];
            markerSymbol.style = symbolStyle;
            markerSymbol.size = markerSize;
            symbol = markerSymbol;
            break;
        }

        case MGSMapAnnotationCircle: {
            AGSSimpleMarkerSymbolStyle symbolStyle = AGSSimpleMarkerSymbolStyleCircle;
            AGSSimpleMarkerSymbol *markerSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:markerColor];
            markerSymbol.style = symbolStyle;
            markerSymbol.size = markerSize;
            symbol = markerSymbol;
        }
            break;

        case MGSMapAnnotationIcon:
        {
            UIImage *markerImage = self.dataLayer.pinIcon;
            AGSPictureMarkerSymbol *pictureSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:markerImage];
            pictureSymbol.yoffset = (CGFloat) (ceil(markerImage.size.height / 2.0) - 1);
            symbol = pictureSymbol;
            break;
        }

        default:
            break;
    }

    return [AGSSimpleRenderer simpleRendererWithSymbol:symbol];
}

/* TODO: Rewrite this method, it's going to be *SLOW* */
- (void)refreshLayer {
    AGSRenderer *renderer = [self agsRenderer];
    [self.graphicsLayer removeAllGraphics];
    self.graphicsLayer.renderer = renderer;

    [self.annotationLayer.annotations enumerateObjectsUsingBlock:^(MGSMapAnnotation *annotation, BOOL *stop) {

    }];
}
@end
