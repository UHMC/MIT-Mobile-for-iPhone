#import <UIKit/UIKit.h>
#import "LocationSearchDelegate.h"

@interface LocationSearchController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic,assign) id<LocationSearchDelegate> resultDelegate;
- (id)init;

@end
