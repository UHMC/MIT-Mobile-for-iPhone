#import <UIKit/UIKit.h>
#import "LocationSearchDelegate.h"

@interface LocationSearchController : NSObject <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate>
@property (nonatomic,readonly,strong) UIViewController *contentsController;
@property (nonatomic,readonly,strong) UISearchBar *searchBar;
@property (nonatomic,assign) id<LocationSearchDelegate> resultDelegate;

@property (nonatomic,assign) BOOL allowsFreeTextEntry;
@property (nonatomic,assign) BOOL showRecentSearches;

- (id)initWithContentsController:(UIViewController*)contentsController;
- (void)clearRecentSearches;
@end
