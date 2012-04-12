#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "LocationSearchDelegate.h"

@class FacilitiesLocation;
@class FacilitiesCategory;
@class MITLoadingActivityView;
@class FacilitiesLocationData;
@class HighlightTableViewCell;
@class FacilitiesLocationSearch;

@interface FacilitiesLocationViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,LocationSearchDelegate>
@property (nonatomic,retain) NSManagedObjectID* categoryID;

@end
