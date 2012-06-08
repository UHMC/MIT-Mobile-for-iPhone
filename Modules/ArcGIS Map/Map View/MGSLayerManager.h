#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>
#import "MGSMapLayer.h"

@interface MGSLayerManager : NSObject
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, readonly, strong) MGSMapLayer *dataLayer;
@property (nonatomic, readonly, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) UIView<AGSLayerView> *graphicsView;
@property (nonatomic, strong) id<AGSInfoTemplateDelegate> infoTemplateDelegate;

+ (id)layerManagerWithMapLayer:(MGSMapLayer*)layer
                 graphicsLayer:(AGSGraphicsLayer*)graphicsLayer;
+ (BOOL)canManageLayer:(MGSMapLayer*)layer;

- (id)initWithLayer:(MGSMapLayer*)layer graphicsLayer:(AGSGraphicsLayer*)graphicLayer;
- (void)refreshLayer;

- (void)layerDidLoad;
- (void)layerFailedToLoad;
@end
