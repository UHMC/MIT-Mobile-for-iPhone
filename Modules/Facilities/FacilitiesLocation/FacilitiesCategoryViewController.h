#import <UIKit/UIKit.h>
#import "LocationSearchDelegate.h"

@class FacilitiesLocation;
@class FacilitiesCategory;
@class MITLoadingActivityView;
@class FacilitiesLocationData;
@class HighlightTableViewCell;
@class FacilitiesLocationSearch;

@interface FacilitiesCategoryViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,LocationSearchDelegate>
@property (nonatomic,retain) UITableView* tableView;
@property (nonatomic,retain) MITLoadingActivityView* loadingView;
@property (retain) FacilitiesLocationData* locationData;

@end
