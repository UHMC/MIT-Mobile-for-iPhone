#import "FacilitiesCategoryViewController.h"

#import "FacilitiesCategory.h"
#import "FacilitiesConstants.h"
#import "FacilitiesLocation.h"
#import "FacilitiesLocationData.h"
#import "FacilitiesLocationViewController.h"
#import "FacilitiesLeasedViewController.h"
#import "FacilitiesRoomViewController.h"
#import "FacilitiesTypeViewController.h"
#import "FacilitiesUserLocationViewController.h"
#import "HighlightTableViewCell.h"
#import "MITLoadingActivityView.h"
#import "UIKit+MITAdditions.h"
#import "LocationSearchController.h"
#import "CoreDataManager.h"


@interface FacilitiesCategoryViewController ()
@property (nonatomic,strong) LocationSearchController *locationSearchController;
@property (nonatomic,strong) NSArray *cachedData;

- (BOOL)shouldShowLocationSection;
- (void)loadDataForMainTableView;
- (void)configureMainTableCell:(UITableViewCell*)cell forIndexPath:(NSIndexPath*)indexPath;
@end

@implementation FacilitiesCategoryViewController
@synthesize tableView = _tableView;
@synthesize loadingView = _loadingView;
@synthesize locationData = _locationData;
@synthesize cachedData = _cachedData;
@synthesize locationSearchController = _locationSearchController;

- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"Where is it?";
        self.locationData = [FacilitiesLocationData sharedData];
    }
    return self;
}

- (void)dealloc
{
    self.tableView = nil;
    self.cachedData = nil;
	self.locationData = nil;
    self.loadingView = nil;
    self.cachedData = nil;
    self.locationSearchController = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle
- (void)loadView {
    CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
    
    UIView *mainView = [[[UIView alloc] initWithFrame:screenFrame] autorelease];
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor clearColor];
    
    
    CGRect searchBarFrame = CGRectZero;
    
    {
        LocationSearchController *controller = [[[LocationSearchController alloc] initWithContentsController:self] autorelease];
        controller.resultDelegate = self;
        controller.searchBar.barStyle = UIBarStyleBlackOpaque;
        controller.allowsFreeTextEntry = YES;
        
        self.locationSearchController = controller;
        
        [controller.searchBar sizeToFit];
        searchBarFrame = controller.searchBar.frame;
        [mainView addSubview:controller.searchBar];
    }
    
    {
        CGRect tableRect = screenFrame;
        tableRect.origin = CGPointMake(0, searchBarFrame.size.height);
        tableRect.size.height -= searchBarFrame.size.height;
        
        UITableView *tableView = [[[UITableView alloc] initWithFrame: tableRect
                                                               style: UITableViewStyleGrouped] autorelease];
        [tableView applyStandardColors];
        
        tableView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                           UIViewAutoresizingFlexibleWidth);
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.hidden = YES;
        tableView.scrollEnabled = YES;
        tableView.autoresizesSubviews = YES;
        
        self.tableView = tableView;
        [mainView addSubview:tableView];
    }
    
    
    {
        CGRect loadingFrame = screenFrame;
        loadingFrame.origin = CGPointMake(0, searchBarFrame.size.height);
        loadingFrame.size.height -= searchBarFrame.size.height;
        
        MITLoadingActivityView *loadingView = [[[MITLoadingActivityView alloc] initWithFrame:loadingFrame] autorelease];
        loadingView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                             UIViewAutoresizingFlexibleWidth);
        loadingView.backgroundColor = [UIColor clearColor];
        
        self.loadingView = loadingView;
        [mainView insertSubview:loadingView
                   aboveSubview:self.tableView];
    }
    
    self.view = mainView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:nil
                                                                  action:nil];
    self.navigationItem.backBarButtonItem = [backButton autorelease];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
    self.cachedData = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Private Methods
- (BOOL)shouldShowLocationSection {
    if ((self.cachedData == nil) || ([self.cachedData count] == 0)) {
        return NO;
    } else {
        return [CLLocationManager locationServicesEnabled];
    }
}


#pragma mark - Public Methods
- (void)loadDataForMainTableView {
    static BOOL requestActive = NO;
    
    if (requestActive == NO)
    {
        requestActive = YES;
        [self.locationData allCategories:^(NSSet *objectIDs, NSError *error) {
            NSArray *categories = [[[CoreDataManager coreDataManager] objectsForObjectIDs:objectIDs] allObjects];
            categories = [categories sortedArrayUsingComparator: ^(id obj1, id obj2) {
                FacilitiesCategory *c1 = (FacilitiesCategory*)obj1;
                FacilitiesCategory *c2 = (FacilitiesCategory*)obj2;
                
                return [c1.name compare:c2.name];
            }];
            
            requestActive = NO;
            
            if ([self.loadingView superview]) {
                [self.loadingView removeFromSuperview]; 
                self.loadingView = nil;
                self.tableView.hidden = NO;
            }
            
            self.cachedData = categories;
            [self.tableView reloadData];
        }];
    }
}

- (void)configureMainTableCell:(UITableViewCell *)cell
                  forIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.section == 0) && ([self shouldShowLocationSection])) {
        cell.textLabel.text = @"Use my location";
    } else {
        FacilitiesCategory *cat = (FacilitiesCategory*)[self.cachedData objectAtIndex:indexPath.row];
        cell.textLabel.text = cat.name;
    }
}


#pragma mark - Dynamic Setters/Getters
- (void)setCachedData:(NSArray *)cachedData {
    [_cachedData release];
    _cachedData = [cachedData retain];
}

- (NSArray*)cachedData {
    if (_cachedData == nil) {
        [self loadDataForMainTableView];
    }
    
    return _cachedData;
}

#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *nextViewController = nil;
    
    if ((indexPath.section == 0) && [self shouldShowLocationSection]) {
        nextViewController = [[[FacilitiesUserLocationViewController alloc] init] autorelease];
    } else {
        FacilitiesCategory *category = (FacilitiesCategory*)[self.cachedData objectAtIndex:indexPath.row];
        FacilitiesLocationViewController *controller = [[[FacilitiesLocationViewController alloc] init] autorelease];
        controller.category = category;
        nextViewController = controller;
    }
    
    [self.navigationController pushViewController:nextViewController
                                         animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ([self shouldShowLocationSection] ? 2 : 1);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ((section == 0) && [self shouldShowLocationSection]) ? 1 : [self.cachedData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *facilitiesIdentifier = @"facilitiesCell";
    
    UITableViewCell *cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:facilitiesIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:facilitiesIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    [self configureMainTableCell:cell 
                    forIndexPath:indexPath];
    return cell;
}

#pragma mark - LocationSearchDelelgate
- (void)locationSearch:(LocationSearchController*)controller didFailWithError:(NSError*)error
{
    
}

- (void)locationSearch:(LocationSearchController*)controller didFinishWithSearchString:(NSString*)string
{
    FacilitiesTypeViewController *vc = [[[FacilitiesTypeViewController alloc] init] autorelease];
    vc.userData = [NSDictionary dictionaryWithObject: string
                                              forKey: FacilitiesRequestLocationUserBuildingKey];
    [self.navigationController pushViewController:vc
                                         animated:YES];
}

- (void)locationSearch:(LocationSearchController*)controller didFinishWithResult:(FacilitiesLocation*)location
{
    UIViewController *nextViewController = nil;
    if ([location.isLeased boolValue])
    {
        FacilitiesLeasedViewController *controller = [[[FacilitiesLeasedViewController alloc] initWithLocation:location] autorelease];
        nextViewController = controller;
    }
    else
    {
        FacilitiesRoomViewController *controller = [[[FacilitiesRoomViewController alloc] init] autorelease];
        controller.location = location;
        nextViewController = controller;
    }
    
    [self.navigationController pushViewController:nextViewController
                                         animated:YES];
}
@end
