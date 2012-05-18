#import <UIKit/UIKit.h>
#import "MITMapView.h"
#import "ShuttleDataManager.h"
#import "MITMobileWebAPI.h"
#import "MITModuleURL.h"
#import "CMModule.h"

@class MITMapSearchResultsVC;
@class MapSelectionController;
@class CampusMapToolbar;

@interface CampusMapViewController : UIViewController <UISearchBarDelegate, 
														MITMapViewDelegate,
														JSONLoadedDelegate,
														ShuttleDataManagerDelegate, 
														UIAlertViewDelegate>

@property (nonatomic) BOOL displayingList;
@property (nonatomic) BOOL hasSearchResults;
@property (nonatomic, assign) CMModule* campusMapModule;

@property (nonatomic, readonly, strong) IBOutlet UIButton* bookmarkButton;
@property (nonatomic, readonly, strong) IBOutlet UISearchBar* searchBar;
@property (nonatomic, readonly, strong) MITMapView* mapView;
@property (nonatomic, readonly, strong) MITModuleURL* url;
@property (nonatomic, strong) NSArray* searchResults;
@property (nonatomic, readonly, strong) NSString* lastSearchText;
@property (nonatomic, readonly, strong) UIBarButtonItem* geoButton;

// execute a search
-(void) search:(NSString*)searchText;

// this is called in handleLocalPath: query: and also by setSearchResults:
- (void)setSearchResults:(NSArray*)searchResults recenterMap:(BOOL)recenter;

// show the list view. If false, hides the list view so the map is displayed. 
-(void) showListView:(BOOL)showList;

// a convenience method for adding or removing "userLoc" from the url's path (for saving state)
-(void) setURLPathUserLocation;

// push an annotations detail page onto the stack
-(void) pushAnnotationDetails:(id <MKAnnotation>) annotation animated:(BOOL)animated;

- (void)updateSearchBarWithString:(NSString*)searchQuery;

@end
