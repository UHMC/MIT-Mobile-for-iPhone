#import <UIKit/UIKit.h>

@class FacilitiesLocation;
@class FacilitiesCategory;
@class MITLoadingActivityView;
@class FacilitiesLocationData;
@class HighlightTableViewCell;
@class FacilitiesLocationSearch;

@interface FacilitiesLocationViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,retain) FacilitiesCategory* category;

@end
