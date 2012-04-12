#import "FacilitiesLocationViewController.h"

#import "FacilitiesCategory.h"
#import "FacilitiesConstants.h"
#import "FacilitiesLocation.h"
#import "FacilitiesLeasedViewController.h"
#import "FacilitiesLocationData.h"
#import "FacilitiesRoomViewController.h"
#import "FacilitiesTypeViewController.h"
#import "HighlightTableViewCell.h"
#import "MITLoadingActivityView.h"
#import "UIKit+MITAdditions.h"
#import "LocationSearchController.h"
#import "CoreDataManager.h"

@interface FacilitiesLocationViewController ()
@property (nonatomic,strong) LocationSearchController *locationSearchController;
@property (nonatomic,strong) NSArray* cachedData;
@property (nonatomic,strong) UITableView* tableView;
@property (nonatomic,strong) MITLoadingActivityView* loadingView;
@property (nonatomic,strong) FacilitiesLocationData* locationData;
@property (nonatomic,strong) FacilitiesCategory *category;

- (void)loadDataForMainTableView;
- (void)configureMainTableCell:(UITableViewCell*)cell forIndexPath:(NSIndexPath*)indexPath;
@end

@implementation FacilitiesLocationViewController
@synthesize tableView = _tableView;
@synthesize loadingView = _loadingView;
@synthesize locationData = _locationData;
@synthesize category = _category;
@synthesize locationSearchController = _locationSearchController;
@synthesize cachedData = _cachedData;

@dynamic categoryID;


- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"Where is it?";
        self.locationData = [FacilitiesLocationData sharedData];
        self.category = nil;
    }
    return self;
}

- (void)dealloc
{
    self.category = nil;
    self.tableView = nil;
    self.loadingView = nil;
    self.locationData = nil;
    
    self.cachedData = nil;
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


#pragma mark - Public Methods
- (void)loadDataForMainTableView {
    static BOOL requestActive = NO;
    
    if (requestActive == NO)
    {
        requestActive = YES;
        [self.locationData allLocations:^(NSSet *objectIDs, NSError *error) {
            NSMutableArray *locations = [NSMutableArray array];
            [locations addObjectsFromArray:[[[CoreDataManager coreDataManager] objectsForObjectIDs:objectIDs] allObjects]];
            
            NSMutableArray *predicates = [NSMutableArray array];
            [predicates addObject:[NSPredicate predicateWithFormat:@"isLeased == NO"]];
            
            if (self.category)
            {
                [predicates addObject:[NSPredicate predicateWithFormat:@"ANY categories.uid == %@",self.category.uid]];
            }
            
            NSCompoundPredicate *predicate = [[[NSCompoundPredicate alloc] initWithType:NSAndPredicateType
                                                                         subpredicates:predicates] autorelease];
            [locations filterUsingPredicate:predicate];
            [locations sortUsingComparator:^(id obj1, id obj2) {
                FacilitiesLocation *l1 = (FacilitiesLocation*)obj1;
                FacilitiesLocation *l2 = (FacilitiesLocation*)obj2;
                NSString *k1 = nil;
                NSString *k2 = nil;
                
                if ([l1.number length] == 0) {
                    k1 = l1.name;
                } else {
                    k1 = l1.number;
                }
                
                if ([l2.number length] == 0) {
                    k2 = l2.name;
                } else {
                    k2 = l2.number;
                }
                
                return [k1 compare:k2
                           options:(NSCaseInsensitiveSearch | NSNumericSearch)];
            }];
            
            requestActive = NO;
            
            if (self.loadingView)
            {
                [self.loadingView removeFromSuperview]; 
                self.loadingView = nil;
                self.tableView.hidden = NO;
            }
            
            self.cachedData = locations;
            [self.tableView reloadData];
        }];
    }
}

- (void)configureMainTableCell:(UITableViewCell*)cell
                  forIndexPath:(NSIndexPath*)indexPath {
    if ([self.cachedData count] >= indexPath.row) {
        FacilitiesLocation *location = [self.cachedData objectAtIndex:indexPath.row];
        cell.textLabel.text = [location displayString];
    }
}

#pragma mark - Dynamic Setters/Getters
- (void)setCachedData:(NSArray *)cachedData {
    if (_cachedData != nil) {
        [_cachedData release];
    }
    
    _cachedData = [cachedData retain];
}

- (NSArray*)cachedData {
    if (_cachedData == nil) {
        [self loadDataForMainTableView];
    }
    
    return _cachedData;
}



- (void)setCategoryID:(NSManagedObjectID *)categoryID
{
    NSManagedObjectContext *context = [[CoreDataManager coreDataManager] managedObjectContext];
    NSManagedObject *mo = [context objectWithID:categoryID];
    
    if ([[[mo entity] name] isEqualToString:@"FacilitiesCategory"])
    {
        self.category = (FacilitiesCategory*)mo;
    }
}

- (NSManagedObjectID*)categoryID
{
    return [self.category objectID];
}


#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FacilitiesLocation *location = (FacilitiesLocation*)[self.cachedData objectAtIndex:indexPath.row];
    
    if ([location.isLeased boolValue]) {
        FacilitiesLeasedViewController *controller = [[[FacilitiesLeasedViewController alloc] initWithLocation:location] autorelease];
        
        [self.navigationController pushViewController:controller
                                             animated:YES];
    } else {
        FacilitiesRoomViewController *controller = [[[FacilitiesRoomViewController alloc] init] autorelease];
        controller.locationID = [location objectID];
        
        [self.navigationController pushViewController:controller
                                             animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}


#pragma mark - UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.cachedData count];
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
        controller.locationID = [location objectID];
        nextViewController = controller;
    }
    
    [self.navigationController pushViewController:nextViewController
                                         animated:YES];
}
@end
