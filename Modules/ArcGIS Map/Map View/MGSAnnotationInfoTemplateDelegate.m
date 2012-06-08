#import "MGSAnnotationInfoTemplateDelegate.h"
#import "MGSMapAnnotation.h"
#import "MGSAnnotationLayerManager.h"

@implementation MGSAnnotationInfoTemplateDelegate
+ (id)annotationInfoTemplate
{
    return [[self alloc] init];
}

- (NSString *)titleForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint
{
    MGSMapAnnotation *annotation = [graphic.attributes objectForKey:MGSAnnotationAttributeKey];
    return annotation.title;
}

- (NSString *)detailForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint
{
    MGSMapAnnotation *annotation = [graphic.attributes objectForKey:MGSAnnotationAttributeKey];
    return annotation.detail;
}

-(UIImage*)imageForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint
{
    MGSMapAnnotation *annotation = [graphic.attributes objectForKey:MGSAnnotationAttributeKey];
    return annotation.image;
}
@end
