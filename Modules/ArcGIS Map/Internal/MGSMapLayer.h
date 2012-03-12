#import <UIKit/UIKit.h>
#import "ArcGIS.h"

@protocol MGSMapLayer <NSObject>
- (NSString *)name;
- (AGSGraphicsLayer *)mapLayer;
- (AGSDynamicLayerView *)mapLayerView;
- (id)layerDelegate;

- (void)setHidden:(BOOL)hidden;
- (BOOL)isHidden;

- (BOOL)containsGraphic:(AGSGraphic*)graphic;
- (void)removeLayer;
@end
