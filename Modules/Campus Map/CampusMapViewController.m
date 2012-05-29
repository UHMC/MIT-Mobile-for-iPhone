#import <QuartzCore/QuartzCore.h>
#import "CampusMapViewController.h"
#import "NSString+SBJSON.h"
#import "MITMapSearchResultAnnotation.h"
#import "MITMapSearchResultsVC.h"
#import "MITMapDetailViewController.h"
#import "ShuttleDataManager.h"
#import "ShuttleStopMapAnnotation.h"
#import "ShuttleStopViewController.h"
#import "MITUIConstants.h"
#import "MITConstants.h"
#import "MapSearch.h"
#import "CoreDataManager.h"
#import "MapSelectionController.h"
#import "CoreLocation+MITAdditions.h"
#import "CampusMapToolbar.h"

#define kSearchBarWidth 270
#define kSearchBarCancelWidthDiff 28

#define kAPISearch		@"Search"

#define kNoSearchResultsTag 31678

#define kPreviousSearchLimit 25


@interface CampusMapViewController()
@property (nonatomic) BOOL displayShuttles;
@property (nonatomic) SEL searchFilter;
@property (nonatomic, strong) CampusMapToolbar* toolbar;
@property (nonatomic, strong) CLLocation* userLocation;
@property (nonatomic, strong) MapSelectionController* selectionVC;
@property (nonatomic, strong) MITMapSearchResultsVC* searchResultsVC;
@property (nonatomic, strong) MITMapView* mapView;
@property (nonatomic, strong) MITModuleURL* url;
@property (nonatomic, strong) NSArray* categories;
@property (nonatomic, strong) NSArray* filteredSearchResults;
@property (nonatomic, strong) NSMutableArray* shuttleAnnotations;
@property (nonatomic, strong) NSString* lastSearchText;
@property (nonatomic, strong) UIBarButtonItem* geoButton;
@property (nonatomic, strong) UIBarButtonItem* shuttleButton;
@property (nonatomic, strong) UIBarButtonItem* viewTypeButton;
@property (nonatomic, strong) UIButton* bookmarkButton;
@property (nonatomic, strong) UISearchBar* searchBar;
@property (nonatomic, strong) UITableView* categoryTableView;

- (void)updateMapListButton;
- (void)addAnnotationsForShuttleStops:(NSArray*)shuttleStops;
- (void)noSearchResultsAlert;
- (void)saveRegion; // a convenience method for saving the mapView's current region (for saving state)

- (void)setSearchResults:(NSArray*)searchResults;
- (void)recenterMapWithResults:(NSArray*)searchResults;
@end

@implementation CampusMapViewController
@synthesize bookmarkButton = miv_bookmarkButton;
@synthesize campusMapModule = miv_campusMapModule;
@synthesize categories = miv_categories;
@synthesize categoryTableView = miv_categoryTableView;
@synthesize displayingList = _displayingList;
@synthesize displayShuttles = miv_displayShuttles;
@synthesize filteredSearchResults = miv_filteredSearchResults;
@synthesize geoButton = miv_geoButton;
@synthesize hasSearchResults = _hasSearchResults;
@synthesize lastSearchText = miv_lastSearchText;
@synthesize mapView = miv_mapView;
@synthesize searchBar = miv_searchBar;
@synthesize searchFilter = miv_searchFilter;
@synthesize searchResults = miv_searchResults;
@synthesize searchResultsVC = miv_searchResultsVC;
@synthesize selectionVC = miv_selectionVC;
@synthesize shuttleAnnotations = miv_shuttleAnnotations;
@synthesize shuttleButton = miv_shuttleButton;
@synthesize toolbar = miv_toolbar;
@synthesize url = miv_url;
@synthesize userLocation = miv_userLocation;
@synthesize viewTypeButton = miv_viewTypeButton;


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	// create our own view
	self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 364)];
	
	UIBarButtonItem *viewTypeButton = [[UIBarButtonItem alloc] initWithTitle:@"Browse" style:UIBarButtonItemStylePlain target:self action:@selector(viewTypeChanged:)];
	self.navigationItem.rightBarButtonItem = viewTypeButton;
    self.viewTypeButton = viewTypeButton;
	
	// add a search bar to our view
	UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, kSearchBarWidth, NAVIGATION_BAR_HEIGHT)];
	searchBar.delegate = self;
	searchBar.placeholder = NSLocalizedString(@"Search MIT Campus", nil);
	searchBar.translucent = NO;
	searchBar.tintColor = SEARCH_BAR_TINT_COLOR;
	searchBar.showsBookmarkButton = NO;
	[self.view addSubview:searchBar];
    self.searchBar = searchBar;
    
	// create the map view controller and its view to our view. 
	MITMapView *mapView = [[MITMapView alloc] initWithFrame: CGRectMake(0,
                                                                        searchBar.frame.size.height,
                                                                        320,
                                                                        self.view.frame.size.height - searchBar.frame.size.height)];
	mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	mapView.region = MKCoordinateRegionMake(DEFAULT_MAP_CENTER, DEFAULT_MAP_SPAN);
	mapView.delegate = self;
	[self.view addSubview:mapView];
    [mapView fixateOnCampus];
    self.mapView = mapView;
	
	// add the rest of the toolbar to which we can add buttons
	CampusMapToolbar *toolbar = [[CampusMapToolbar alloc] initWithFrame:CGRectMake(kSearchBarWidth, 0, 320 - kSearchBarWidth, NAVIGATION_BAR_HEIGHT)];
	toolbar.translucent = NO;
	toolbar.tintColor = SEARCH_BAR_TINT_COLOR;
	[self.view addSubview:toolbar];
    self.toolbar = toolbar;
	
	// create toolbar button item for geolocation  
	UIImage* image = [UIImage imageNamed:@"map/map_button_icon_locate.png"];
	UIBarButtonItem *geoButton = [[UIBarButtonItem alloc] initWithImage:image
                                                                  style:UIBarButtonItemStyleBordered
                                                                 target:self
                                                                 action:@selector(geoLocationTouched:)];
	geoButton.width = image.size.width + 10;
    
	[toolbar setItems:[NSArray arrayWithObject:geoButton]];
	
	// add our own bookmark button item since we are not using the default
	// bookmark button of the UISearchBar
	UIButton *bookmarkButton = [[UIButton alloc] initWithFrame:CGRectMake(231, 8, 32, 28)];
	[bookmarkButton setImage:[UIImage imageNamed:@"map/searchfield_star.png"]
                    forState:UIControlStateNormal];
    
	[self.view addSubview:bookmarkButton];
	[bookmarkButton addTarget:self
                       action:@selector(bookmarkButtonClicked:)
             forControlEvents:UIControlEventTouchUpInside];
	
	self.url = [[MITModuleURL alloc] initWithTag:CampusMapTag];
	
}

- (void)setDisplayingList:(BOOL)displayingList {
    _displayingList = displayingList;
    [self updateMapListButton];
}

- (void)setHasSearchResults:(BOOL)hasSearchResults {
    _hasSearchResults = hasSearchResults;
    [self updateMapListButton];
}

- (void)updateMapListButton {
    NSString *buttonTitle = @"Browse";
	if (self.displayingList) {
		buttonTitle = @"Map";
	} else if (self.hasSearchResults) {
        buttonTitle = @"List";
    }
    self.navigationItem.rightBarButtonItem.title = buttonTitle;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Campus Map";
}

-(void) viewWillAppear:(BOOL)animated {
    [self.mapView addTileOverlay];
    self.mapView.showsUserLocation = YES;
    
    [self updateMapListButton];
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.mapView removeTileOverlay];
    self.mapView.showsUserLocation = NO;
}

-(void) viewDidAppear:(BOOL)animated
{
	// show the annotations
	
	[super viewDidAppear:animated];
	
	// if there is a bookmarks view controller hanging around, dismiss and release it. 
	if(self.selectionVC)
	{
		[self.selectionVC dismissModalViewControllerAnimated:NO];
		self.selectionVC = nil;
	}
	
	
	// if we're in the list view, save that state
    MITMapSearchResultAnnotation *searchAnnotation = (MITMapSearchResultAnnotation*)(self.mapView.currentAnnotation);
	if (self.displayingList && searchAnnotation)
    {
        NSString *path = [NSString stringWithFormat:@"list/%@", [searchAnnotation uniqueID]];
		[self.url setPath:path
                    query:self.lastSearchText];
		[self.url setAsModulePath];
		[self setURLPathUserLocation];
	}
    else 
    {
        BOOL shouldSaveState = (([self.lastSearchText length] > 0) && self.mapView.currentAnnotation);
		if (shouldSaveState)
        {
            NSString *path = [NSString stringWithFormat:@"search/%@", [searchAnnotation uniqueID]];
			[self.url setPath:path
                        query:self.lastSearchText];
			[self.url setAsModulePath];
			[self setURLPathUserLocation];
		}
	}
	self.view.hidden = NO;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    //[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[[ShuttleDataManager sharedDataManager] unregisterDelegate:self];
	
    self.mapView.delegate = nil;
    self.mapView = nil;
    
    self.bookmarkButton = nil;
    self.displayingList = NO;
    self.geoButton = nil;
    self.hasSearchResults = NO;
    self.searchBar = nil;
    self.searchResults = nil;
    self.searchResultsVC = nil;
    self.selectionVC = nil;
    self.shuttleAnnotations = nil;
    self.shuttleButton = nil;
    self.toolbar = nil;
    self.url = nil;
    self.viewTypeButton = nil;
}


- (void)setSearchResults:(NSArray*)searchResults
{
    [self setSearchResults:searchResults
               recenterMap:YES];
}

- (void)setSearchResults:(NSArray*)searchResults recenterMap:(BOOL)recenter
{
    miv_searchResults = searchResults;
    
    self.searchFilter = NULL;
	self.filteredSearchResults = nil;
	
	// remove search results
	[self.mapView removeAnnotations:self.searchResults];
	[self.mapView removeAnnotations:self.filteredSearchResults];
	[self.mapView removeAllAnnotations:NO];
	
	
	if (self.searchResultsVC) {
		self.searchResultsVC.searchResults = searchResults;
	}
	
	[self.mapView addAnnotations:searchResults];
    
    if (recenter)
    {
        [self recenterMapWithResults:searchResults];
    }
}

- (void)recenterMapWithResults:(NSArray*)searchResults
{
    if ([searchResults count] > 0) 
	{
		// determine the region for the search results
		double minLat = 90;
		double maxLat = -90;
		double minLon = 180;
		double maxLon = -180;
		
		for (id<MKAnnotation> annotation in searchResults) 
		{
			CLLocationCoordinate2D coordinate = annotation.coordinate;
			
			if (coordinate.latitude < minLat) 
                minLat = coordinate.latitude;
            
			if (coordinate.latitude > maxLat )
                maxLat = coordinate.latitude;
            
			if (coordinate.longitude < minLon) 
                minLon = coordinate.longitude;
            
			if(coordinate.longitude > maxLon)
                maxLon = coordinate.longitude;
		}
		
		CLLocationCoordinate2D center;
		center.latitude = minLat + (maxLat - minLat) / 2;
		center.longitude = minLon + (maxLon - minLon) / 2;
		
		// create the span and region with a little padding
		double latDelta = maxLat - minLat;
		double lonDelta = maxLon - minLon;
		
		if (latDelta < .002) latDelta = .002;
		if (lonDelta < .002) lonDelta = .002;
        
		self.mapView.region = MKCoordinateRegionMake(center, MKCoordinateSpanMake(latDelta + latDelta / 4 , lonDelta + lonDelta / 4));
		
		// turn off locate me
		self.geoButton.style = UIBarButtonItemStyleBordered;
		self.mapView.stayCenteredOnUserLocation = NO;
	}
	
	[self saveRegion];
}

-(MKCoordinateRegion)regionForAnnotations:(NSArray *) annotations {
	
	if ([annotations count] > 0) 
	{
		// determine the region for the search results
		double minLat = 90;
		double maxLat = -90;
		double minLon = 180;
		double maxLon = -180;
		
		for (id<MKAnnotation> annotation in annotations) 
		{
			CLLocationCoordinate2D coordinate = annotation.coordinate;
			
			if (coordinate.latitude < minLat) 
			{
				minLat = coordinate.latitude;
			}
			if (coordinate.latitude > maxLat )
			{
				maxLat = coordinate.latitude;
			}
			if (coordinate.longitude < minLon) 
			{
				minLon = coordinate.longitude;
			}
			if(coordinate.longitude > maxLon)
			{
				maxLon = coordinate.longitude;
			}
			
		}
		
		CLLocationCoordinate2D center;
		center.latitude = minLat + (maxLat - minLat) / 2;
		center.longitude = minLon + (maxLon - minLon) / 2;
		
		// create the span and region with a little padding
		double latDelta = maxLat - minLat;
		double lonDelta = maxLon - minLon;
		
		if (latDelta < .002) latDelta = .002;
		if (lonDelta < .002) lonDelta = .002;
		
		MKCoordinateRegion region = MKCoordinateRegionMake(center, 	MKCoordinateSpanMake(latDelta + latDelta / 4 , lonDelta + lonDelta / 4));
		
		// turn off locate me
		self.geoButton.style = UIBarButtonItemStyleBordered;
		self.mapView.stayCenteredOnUserLocation = NO;
		
		[self saveRegion];
		return region;
	}
	
	else {
		[self saveRegion];
		return MKCoordinateRegionMake(DEFAULT_MAP_CENTER, DEFAULT_MAP_SPAN);
	}
    
}

- (void)updateSearchBarWithString:(NSString*)searchQuery;
{
    self.searchBar.text = searchQuery;
    self.lastSearchText = searchQuery;
}

#pragma mark ShuttleDataManagerDelegate

// message sent when routes were received. If request failed, this is called with a nil routes array
-(void) routesReceived:(NSArray*) routes
{
}

// message sent when stops were received. If request failed, this is called with a nil stops array
-(void) stopsReceived:(NSArray*) stops
{
	if (self.displayShuttles) {
		[self addAnnotationsForShuttleStops:stops];
	}
}

#pragma mark CampusMapViewController(Private)

-(void) addAnnotationsForShuttleStops:(NSArray*)shuttleStops
{
	if (self.shuttleAnnotations == nil) {
		self.shuttleAnnotations = [[NSMutableArray alloc] initWithCapacity:[shuttleStops count]];
	}
	
	for (ShuttleStop* shuttleStop in shuttleStops) 
	{
		ShuttleStopMapAnnotation* annotation = [[ShuttleStopMapAnnotation alloc] initWithShuttleStop:shuttleStop];
		[self.mapView addAnnotation:annotation];
		[self.shuttleAnnotations addObject:annotation];
	}
}

-(void) noSearchResultsAlert
{
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:NSLocalizedString(@"Nothing found.", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
	alert.tag = kNoSearchResultsTag;
	alert.delegate = self;
	[alert show];
}

-(void) setURLPathUserLocation {
	NSArray *components = [self.url.path componentsSeparatedByString:@"/"];
	if (self.mapView.showsUserLocation && ([[components lastObject] isEqualToString:@"userLoc"] == NO))
    {
		[self.url setPath:[NSString stringWithFormat:@"%@/%@", self.url.path, @"userLoc"]
                    query:self.lastSearchText];
		[self.url setAsModulePath];
	}
	else if ((self.mapView.showsUserLocation == NO) && [[components lastObject] isEqualToString:@"userLoc"])
    {
		[self.url setPath:[self.url.path stringByReplacingOccurrencesOfString:@"userLoc" withString:@""]
                    query:self.lastSearchText];
		[self.url setAsModulePath];
	}
}

-(void) saveRegion
{	
	// save this region so we can use it on launch
	NSNumber* centerLat = [NSNumber numberWithDouble:self.mapView.region.center.latitude];
	NSNumber* centerLong = [NSNumber numberWithDouble:self.mapView.region.center.longitude];
	NSNumber* spanLat = [NSNumber numberWithDouble:self.mapView.region.span.latitudeDelta];
	NSNumber* spanLong = [NSNumber numberWithDouble:self.mapView.region.span.longitudeDelta];
	NSDictionary* regionDict = [NSDictionary dictionaryWithObjectsAndKeys:centerLat, @"centerLat",
                                centerLong, @"centerLong",
                                spanLat, @"spanLat",
                                spanLong, @"spanLong", nil];
	
	NSString* docsFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	NSString* regionFilename = [docsFolder stringByAppendingPathComponent:@"region.plist"];
	[regionDict writeToFile:regionFilename atomically:YES];
}

#pragma mark UIAlertViewDelegate
-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// if the alert view was "no search results", give focus back to the search bar
	if (alertView.tag == kNoSearchResultsTag) {
		[self.searchBar becomeFirstResponder];
	}
}


#pragma mark User actions

-(void) geoLocationTouched:(id)sender
{
    if (self.userLocation) {
        CLLocationCoordinate2D center = self.userLocation.coordinate;
        self.mapView.region = MKCoordinateRegionMake(center, DEFAULT_MAP_SPAN);
    }
    
    else {
        // messages to be shown when user taps locate me button off campus
        NSString *message = nil;
        if (arc4random() % 2) {
            message = NSLocalizedString(@"Off Campus Warning 1", nil);
        } else {
            message = NSLocalizedString(@"Off Campus Warning 2", nil); 
        }
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Off Campus", nil)
                                                        message:message 
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
        
        self.mapView.showsUserLocation = NO; // turn off location updating
    }
    
	[self setURLPathUserLocation];
}

-(void) showListView:(BOOL)showList
{
    
	if (showList) {
		// if we are not already showing the list, do all this 
		if (!self.displayingList) {
			// show the list.
			if(self.searchResultsVC == nil)
			{
				MITMapSearchResultsVC *searchResultsVC = [[MITMapSearchResultsVC alloc] initWithNibName:@"MITMapSearchResultsVC" bundle:nil];
				searchResultsVC.title = @"Campus Map";
				searchResultsVC.campusMapVC = self;
                self.searchResultsVC = searchResultsVC;
			}
			
			self.searchResultsVC.searchResults = self.searchResults;
			self.searchResultsVC.view.frame = self.mapView.frame;
            
			[self.view addSubview:self.searchResultsVC.view];
			
			// hide the toolbar and stretch the search bar
			self.toolbar.items = nil;
			self.toolbar.frame =  CGRectMake(kSearchBarWidth, 0, 0, NAVIGATION_BAR_HEIGHT);
			self.searchBar.frame = CGRectMake(self.searchBar.frame.origin.x, 
                                              self.searchBar.frame.origin.y,
                                              self.view.frame.size.width,
                                              self.searchBar.frame.size.height);
			self.bookmarkButton.frame = CGRectMake(281, 8, 32, 28);
			
			[self.url setPath:@"list"
                        query:self.lastSearchText];
			[self.url setAsModulePath];
			[self setURLPathUserLocation];
		}
	}
	else {
		// if we're not already showing the map
		if (self.displayingList) {
			// show the map, by hiding the list. 
			[self.searchResultsVC.view removeFromSuperview];
			self.searchResultsVC = nil;
			
			// show the toolbar and shrink the search bar. 
			self.toolbar.frame =  CGRectMake(kSearchBarWidth, 0, 320 - kSearchBarWidth, NAVIGATION_BAR_HEIGHT);
			self.toolbar.items = [NSArray arrayWithObject:self.geoButton];
			self.searchBar.frame = CGRectMake(self.searchBar.frame.origin.x, 
                                              self.searchBar.frame.origin.y,
                                              kSearchBarWidth,
                                              self.searchBar.frame.size.height);
			self.bookmarkButton.frame = CGRectMake(231, 8, 32, 28);
		}
        
		// only let the user switch to the list view if there are search results.
        BOOL canSwitchToListView = (([self.lastSearchText length] > 0) &&
                                    self.mapView.currentAnnotation);
		if (canSwitchToListView)
        {
            MITMapSearchResultAnnotation *annotation = self.mapView.currentAnnotation;
			[self.url setPath:[NSString stringWithFormat:@"search/%@", [annotation uniqueID]]
                        query:self.lastSearchText];
        }
		else
        {
			[self.url setPath:@""
                        query:nil];
        }
        
		[self.url setAsModulePath];
		[self setURLPathUserLocation];
	}
	
	self.displayingList = showList;
}

-(void) viewTypeChanged:(id)sender
{
	// resign the search bar, if it was first selector
	[self.searchBar resignFirstResponder];
	
	// if there is nothing in the search bar, we are browsing categories; otherwise go to list view
	if (!self.displayingList && !self.hasSearchResults) {
		if(self.selectionVC)
		{
			[self.selectionVC dismissModalViewControllerAnimated:NO];
			self.selectionVC = nil;
		}
		
		MapSelectionController *selectionVC = [[MapSelectionController alloc]  initWithMapSelectionControllerSegment:MapSelectionControllerSegmentBrowse campusMap:self];
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        self.selectionVC = selectionVC;
		[appDelegate presentAppModalViewController:selectionVC
                                          animated:YES];
	} else {	
		[self showListView:!self.displayingList];
	}
	
}

-(void) receivedNewSearchResults:(NSArray*)searchResults forQuery:(NSString *)searchQuery
{
	
	NSMutableArray* searchResultsArr = [NSMutableArray arrayWithCapacity:[searchResults count]];
	
	for (NSDictionary* info in searchResults)
	{
		MITMapSearchResultAnnotation* annotation = [[MITMapSearchResultAnnotation alloc] initWithInfo:info];
		[searchResultsArr addObject:annotation];
	}
	
	// this will remove old annotations and add the new ones. 
	self.searchResults = searchResultsArr;
	
	NSString* docsFolder = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	NSString* searchResultsFilename = [docsFolder stringByAppendingPathComponent:@"searchResults.plist"];
	[searchResults writeToFile:searchResultsFilename atomically:YES];
	[[NSUserDefaults standardUserDefaults] setObject:searchQuery forKey:CachedMapSearchQueryKey];
    
}

#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
	self.bookmarkButton.hidden = YES;
	
	// Add the cancel button, and remove the geo button. 
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:self
                                                                    action:@selector(cancelSearch)];
	
	if (self.displayingList) {
		self.toolbar.frame = CGRectMake(320, 0, 320 - kSearchBarWidth + kSearchBarCancelWidthDiff, NAVIGATION_BAR_HEIGHT);
	}
	
	[UIView beginAnimations:@"searching" context:nil];
    [UIView setAnimationDuration:0.3];
	self.searchBar.frame = CGRectMake(0, 0, kSearchBarWidth - kSearchBarCancelWidthDiff, NAVIGATION_BAR_HEIGHT);
	[self.searchBar setNeedsLayout];
    
	self.bookmarkButton.frame = CGRectMake(231 - kSearchBarCancelWidthDiff, 8, 32, 28);
    
	[self.toolbar setItems:[NSArray arrayWithObjects:cancelButton, nil]];
	self.toolbar.frame = CGRectMake(kSearchBarWidth - kSearchBarCancelWidthDiff, 0, 320 - kSearchBarWidth + kSearchBarCancelWidthDiff, NAVIGATION_BAR_HEIGHT);
	[UIView commitAnimations];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	// when we're not editing, make sure the bookmark button is put back
	self.bookmarkButton.hidden = NO;
	
	
	[UIView beginAnimations:@"doneSearching" context:nil];
	self.searchBar.frame = CGRectMake(0, 0, self.displayingList ? self.view.frame.size.width : kSearchBarWidth, NAVIGATION_BAR_HEIGHT);
	[self.searchBar setNeedsLayout];
    
    if (self.displayingList)
    {
        [self.toolbar setItems:[NSArray arrayWithObject:self.geoButton]];
    }
    else
    {
        [self.toolbar setItems:nil];
    }
    
	self.toolbar.frame = CGRectMake( self.displayingList ? 320 : kSearchBarWidth, 0, 320 - kSearchBarWidth, NAVIGATION_BAR_HEIGHT);
	self.bookmarkButton.frame = self.displayingList ? CGRectMake(281, 8, 32, 28) : CGRectMake(231, 8, 32, 28);
    
	[UIView commitAnimations];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{	
	[searchBar resignFirstResponder];
	
	// delete any previous instance of this search term
	MapSearch* mapSearch = [CoreDataManager getObjectForEntity:CampusMapSearchEntityName attribute:@"searchTerm" value:searchBar.text];
	if(nil != mapSearch)
	{
		[CoreDataManager deleteObject:mapSearch];
	}
	
	// insert the new instance of this search term
	mapSearch = [CoreDataManager insertNewObjectForEntityForName:CampusMapSearchEntityName];
	mapSearch.searchTerm = searchBar.text;
	mapSearch.date = [NSDate date];
	[CoreDataManager saveData];
	
	
	// determine if we are past our max search limit. If so, trim an item
	NSError* error = nil;
	
	NSFetchRequest* countFetchRequest = [[NSFetchRequest alloc] init];
	[countFetchRequest setEntity:[NSEntityDescription entityForName:CampusMapSearchEntityName
                                             inManagedObjectContext:[CoreDataManager managedObjectContext]]];
	NSUInteger count = 	[[CoreDataManager managedObjectContext] countForFetchRequest:countFetchRequest error:&error];
	
	// cap the number of previous searches maintained in the DB. If we go over the limit, delete one. 
	if((nil == error) && (count > kPreviousSearchLimit))
	{
		// get the oldest item
		NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
		NSFetchRequest* limitFetchRequest = [[NSFetchRequest alloc] init];		
		[limitFetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		[limitFetchRequest setEntity:[NSEntityDescription entityForName:CampusMapSearchEntityName inManagedObjectContext:[CoreDataManager managedObjectContext]]];
		[limitFetchRequest setFetchLimit:1];
		NSArray* overLimit = [[CoreDataManager managedObjectContext] executeFetchRequest: limitFetchRequest error:nil];
        
		if(overLimit && [overLimit count] == 1)
		{
			[[CoreDataManager managedObjectContext] deleteObject:[overLimit objectAtIndex:0]];
		}
        
		[CoreDataManager saveData];
	}
	
	// ask the campus map view controller to perform the search
	[self search:searchBar.text];
	
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
	self.hasSearchResults = NO;
	[searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	// clear search result if search string becomes empty
	if (searchText.length == 0 ) {		
		self.hasSearchResults = NO;
		// tell the campus view controller to remove its search results. 
		[self search:nil];
	}
}

-(void) touchEnded
{
	[self.searchBar resignFirstResponder];
}

-(void) cancelSearch
{
	[self.searchBar resignFirstResponder];
}

#pragma mark Custom Bookmark Button Functionality

- (void)bookmarkButtonClicked:(UIButton *)sender
{
	if(self.selectionVC)
	{
		[self.selectionVC dismissModalViewControllerAnimated:NO];
		self.selectionVC = nil;
	}
	
	MapSelectionController *controller = [[MapSelectionController alloc]  initWithMapSelectionControllerSegment:MapSelectionControllerSegmentBookmarks
                                                                                                      campusMap:self];
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.selectionVC = controller;
    
	[appDelegate presentAppModalViewController:controller
                                      animated:YES];
}

#pragma mark MITMapViewDelegate

-(void) mapViewRegionDidChange:(MITMapView*)mapView
{
	[self setURLPathUserLocation];
	
	[self saveRegion];
}

- (void)mapViewRegionWillChange:(MITMapView*)mapView
{
	//_geoButton.style = _mapView.stayCenteredOnUserLocation ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
	
	[self setURLPathUserLocation];
}

-(void) pushAnnotationDetails:(id <MKAnnotation>) annotation animated:(BOOL)animated
{
	// determine the type of the annotation. If it is a search result annotation, display the details
	if ([annotation isKindOfClass:[MITMapSearchResultAnnotation class]]) 
	{
		
		// push the details page onto the stack for the item selected. 
		MITMapDetailViewController* detailsVC = [[MITMapDetailViewController alloc] initWithNibName:@"MITMapDetailViewController"
                                                                                             bundle:nil];
		
		detailsVC.annotation = annotation;
		detailsVC.title = @"Info";
		detailsVC.campusMapVC = self;
		
		if(!((MITMapSearchResultAnnotation*)annotation).bookmark)
		{
            
			if(self.lastSearchText != nil && self.lastSearchText.length > 0)
			{
				detailsVC.queryText = self.lastSearchText;
			}
		}
		[self.navigationController pushViewController:detailsVC animated:animated];		
	}
	else if ([annotation isKindOfClass:[ShuttleStopMapAnnotation class]])
	{
		
		// move this logic to the shuttle module
		ShuttleStopViewController* shuttleStopVC = [[ShuttleStopViewController alloc] initWithStyle:UITableViewStyleGrouped];
		shuttleStopVC.shuttleStop = [(ShuttleStopMapAnnotation*)annotation shuttleStop];
		[self.navigationController pushViewController:shuttleStopVC animated:animated];
		
	}
	if ([annotation class] == [MITMapSearchResultAnnotation class]) {
		MITMapSearchResultAnnotation* theAnnotation = (MITMapSearchResultAnnotation*)annotation;
        
		if (self.displayingList)
			[self.url setPath:[NSString stringWithFormat:@"list/detail/%@", theAnnotation.uniqueID]
                        query:self.lastSearchText];
		else 
			[self.url setPath:[NSString stringWithFormat:@"detail/%@", theAnnotation.uniqueID]
                   query:self.lastSearchText];
		[self.url setAsModulePath];
		[self setURLPathUserLocation];
	}	
}

// a callout accessory control was tapped. 
- (void)mapView:(MITMapView *)mapView annotationViewCalloutAccessoryTapped:(MITMapAnnotationView *)view 
{
	[self pushAnnotationDetails:view.annotation animated:YES];
}

- (void)mapView:(MITMapView *)mapView wasTouched:(UITouch*)touch
{
	[self.searchBar resignFirstResponder];
}

- (void)mapView:(MITMapView *)mapView annotationSelected:(id<MKAnnotation>)annotation {
	if([annotation isKindOfClass:[MITMapSearchResultAnnotation class]])
	{
		MITMapSearchResultAnnotation* searchAnnotation = (MITMapSearchResultAnnotation*)annotation;
		// if the annotation is not fully loaded, try to load it
		if (!searchAnnotation.dataPopulated)
		{	
			[MITMapSearchResultAnnotation executeServerSearchWithQuery:searchAnnotation.bldgnum
                                                          jsonDelegate:self
                                                                object:annotation];	
		}
		[self.url setPath:[NSString stringWithFormat:@"search/%@", searchAnnotation.uniqueID]
                    query:self.lastSearchText];
		[self.url setAsModulePath];
		[self setURLPathUserLocation];
	}
}

-(void) locateUserFailed:(MITMapView *)mapView
{
	if (self.mapView.stayCenteredOnUserLocation) 
	{
		self.geoButton.style = UIBarButtonItemStyleBordered;
	}	
}

- (void)mapView:(MITMapView *)mapView didUpdateUserLocation:(CLLocation *)userLocation {
    
    if ([userLocation isNearCampus]) {
        self.userLocation = userLocation;
    }
}

#pragma mark JSONLoadedDelegate

- (void) request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject
{	
	NSArray *searchResults = JSONObject;
	if ([request.userData isKindOfClass:[NSString class]]) {
		NSString *searchType = request.userData;
        
		if ([searchType isEqualToString:kAPISearch])
		{		
			self.lastSearchText = [request.params objectForKey:@"q"];
            
			[self receivedNewSearchResults:searchResults
                                  forQuery:self.lastSearchText];
            
			// if there were no search results, tell the user about it. 
			if(nil == searchResults || [searchResults count] <= 0) {
				[self noSearchResultsAlert];
				self.hasSearchResults = NO;
			} else {
				self.hasSearchResults = YES;
			}
		}
	}
    
	
	else if([request.userData isKindOfClass:[MITMapSearchResultAnnotation class]]) {
		// updating an annotation search request
		MITMapSearchResultAnnotation* oldAnnotation = request.userData;
		NSArray* results = JSONObject;
		
		if ([results count] > 0) 
		{
			MITMapSearchResultAnnotation* newAnnotation = [[MITMapSearchResultAnnotation alloc] initWithInfo:[results objectAtIndex:0]];
			
			BOOL isViewingAnnotation = (self.mapView.currentAnnotation == oldAnnotation);
			
			[self.mapView removeAnnotation:oldAnnotation];
			[self.mapView addAnnotation:newAnnotation];
			
			if (isViewingAnnotation) {
				[self.mapView selectAnnotation:newAnnotation
                                      animated:NO
                                  withRecenter:NO];
			}
			self.hasSearchResults = YES;
		} else {
			self.hasSearchResults = NO;
		}
	}	
}

// there was an error connecting to the specified URL.
- (BOOL) request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
	return ([(NSString *)request.userData isEqualToString:kAPISearch]);
}

- (NSString *) request:(MITMobileWebAPI *)request displayHeaderForError:(NSError *)error {
	return @"Campus Map";
}

#pragma mark UITableViewDataSource

-(void) search:(NSString*)searchText
{	
	if (nil == searchText) 
	{
		self.searchResults = nil;
        self.lastSearchText = nil;
	}
	else
	{		
		[MITMapSearchResultAnnotation executeServerSearchWithQuery:searchText jsonDelegate:self object:kAPISearch];
	}
    
	if (self.displayingList)
		[self.url setPath:@"list"
               query:searchText];
	else if (searchText != nil && ![searchText isEqualToString:@""])
		[self.url setPath:@"search"
                    query:searchText];
	else 
		[self.url setPath:@""
                    query:nil];
	[self.url setAsModulePath];
	[self setURLPathUserLocation];
}


@end
