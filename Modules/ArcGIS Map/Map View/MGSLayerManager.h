#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@class MGSMapLayer;

@interface MGSLayerManager : NSObject
@property (nonatomic, readonly, strong) MGSMapLayer *dataLayer;
@property (nonatomic, readonly, strong) AGSGraphicsLayer *graphicsLayer;

+ (BOOL)canManageLayer:(MGSMapLayer*)layer;
- (id)initWithLayer:(MGSMapLayer*)layer graphicsLayer:(AGSGraphicsLayer*)graphicLayer;
- (void)refreshLayer;
@end
