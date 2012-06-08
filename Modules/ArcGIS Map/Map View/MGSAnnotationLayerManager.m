#import "MGSAnnotationLayerManager.h"
#import "MGSAnnotationLayer.h"
#import "MGSMapAnnotation.h"
#import "MGSMapCoordinate+AGS.h"
#import "MGSAnnotationInfoTemplateDelegate.h"

#define unless(x) if (!(x))

NSString const *MGSAnnotationAttributeKey = @"MGSAnnotationSetAttribute";

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

    if (self)
    {
        self.infoTemplateDelegate = [MGSAnnotationInfoTemplateDelegate annotationInfoTemplate];
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
        case MGSMapAnnotationSquare:
        {
            AGSSimpleMarkerSymbolStyle symbolStyle = AGSSimpleMarkerSymbolStyleSquare;
            AGSSimpleMarkerSymbol *markerSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:markerColor];
            markerSymbol.style = symbolStyle;
            markerSymbol.size = markerSize;
            symbol = markerSymbol;
            break;
        }

        case MGSMapAnnotationCircle:
        {
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
            
            
        case MGSMapAnnotationPin:
        default:
        {
            AGSPictureMarkerSymbol *pictureSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"map/map_pin_complete"];
            pictureSymbol.yoffset = (CGFloat) (ceil(pictureSymbol.image.size.height / 2.0) - 1);
            symbol = pictureSymbol;
            break;
        }
    }

    return [AGSSimpleRenderer simpleRendererWithSymbol:symbol];
}

- (void)setGraphicsView:(UIView<AGSLayerView> *)graphicsView
{
    [super setGraphicsView:graphicsView];
    
    if (graphicsView)
    {
        [self refreshLayer];
    }
}

/* FIXME: Rewrite this method, it's going to be *SLOW* */
- (void)refreshLayer {
    
    if (self.graphicsView)
    {
        AGSSpatialReference *spatialReference = self.graphicsView.mapView.spatialReference;
        
        [self.graphicsLayer removeAllGraphics];
        self.graphicsLayer.renderer = [self agsRenderer];

        NSMutableArray *newGraphics = [NSMutableArray array];
        [self.annotationLayer.annotations enumerateObjectsUsingBlock:^(MGSMapAnnotation *annotation, BOOL *stop) {
            AGSPoint *point = [annotation.coordinate agsPoint];
            AGSPoint *pointConv = (AGSPoint*)[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:point
                                                                                     toSpatialReference:spatialReference];
            
            AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:pointConv
                                                           symbol:nil
                                                       attributes:[NSDictionary dictionaryWithObject:annotation
                                                                                              forKey:MGSAnnotationAttributeKey]
                                             infoTemplateDelegate:nil];
            
            if (self.infoTemplateDelegate)
            {
                graphic.infoTemplateDelegate = self.infoTemplateDelegate;
            }
            
            [newGraphics addObject:graphic];
        }];
        
        [self.graphicsLayer addGraphics:newGraphics];
        [self.graphicsLayer dataChanged];
        [self.graphicsView setNeedsDisplay];
    }
}
@end
