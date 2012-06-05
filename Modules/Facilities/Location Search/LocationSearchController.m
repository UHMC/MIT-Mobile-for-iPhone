#import <CoreData/CoreData.h>
#import "LocationSearchController.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"
#import "HighlightTableViewCell.h"
#import "LocationSearchOperation.h"
#import "MITLogging.h"
#import "MITLoadingActivityView.h"

enum {
    LocationSearchSectionAsEnteredIndex = 0,
    LocationSearchSectionRecentIndex,
    LocationSearchSectionQueryIndex
};

static NSString *LocationSearchSectionAsEnteredKey = @"edu.mit.mobile.location.search.AsEntered";
static NSString *LocationSearchSectionRecentKey = @"edu.mit.mobile.location.search.RecentSearches";
static NSString *LocationSearchSectionQueryKey = @"edu.mit.mobile.location.search.QueryResults";

@interface LocationSearchController ()
@property (nonatomic,strong) UISearchDisplayController *searchDisplayController;
@property (nonatomic,strong) UIViewController *contentsController;
@property (nonatomic,strong) UISearchBar *searchBar;
@property (nonatomic,strong) MITLoadingActivityView *loadingView;

@property (nonatomic,strong) NSString *queryString;
@property (strong) NSString *pendingQueryString;
@property (nonatomic,strong) NSMutableArray *queryResults;

@property (nonatomic,strong) NSMutableArray *recentSearches;
@property (nonatomic,strong) NSArray *filteredRecentSearches;

@property (nonatomic,strong) NSOperationQueue *searchQueue;

@property (nonatomic,strong) NSMutableArray *tableSections;
@property (nonatomic,strong) NSMutableDictionary *tableData;

+ (NSComparator)queryResultsComparator;
- (void)addStringToRecentSearches:(NSString*)string;

#pragma mark - Table Section Management (@interface)
- (void)deleteSectionWithIdentifier:(NSString*)identifier;
- (void)addSectionIdentifier:(NSString*)identifier withData:(id)data;
- (BOOL)isSectionVisible:(NSString*)identifier;
- (id)dataForSectionWithIdentifier:(NSString*)identifier;
- (void)setData:(id)data forSectionWithIdentifier:(NSString*)identifier;
- (NSString*)identifierForSectionIndex:(NSInteger)section;
- (NSInteger)sectionIndexForIdentifier:(NSString*)identifier;
#pragma mark -
@end

@implementation LocationSearchController
@synthesize resultDelegate = _resultDelegate;
@synthesize recentSearches = _allRecentSearches;
@synthesize queryString = _queryString;
@synthesize pendingQueryString = _pendingQueryString;
@synthesize searchDisplayController = _searchDisplayController;
@synthesize contentsController = _contentsController;
@synthesize searchBar = _searchBar;
@synthesize searchQueue = _searchQueue;
@synthesize tableData = _tableData;
@synthesize tableSections = _tableSections;
@synthesize loadingView = _loadingView;

@dynamic allowsFreeTextEntry;
@dynamic showRecentSearches;
@dynamic queryResults;
@dynamic filteredRecentSearches;

+ (NSComparator)queryResultsComparator
{
    NSComparator comparatorBlock = ^(id obj1, id obj2) {
        NSString *key1 = [obj1 valueForKey:LocationSearchResultDisplayStringKey];
        NSString *key2 = [obj2 valueForKey:LocationSearchResultDisplayStringKey];
        
        return [key1 compare:key2
                     options:(NSCaseInsensitiveSearch |
                              NSNumericSearch |
                              NSForcedOrderingSearch)];
    };
    
    return [[comparatorBlock copy] autorelease];
}

- (id)initWithContentsController:(UIViewController *)contentsController
{
    self = [super init];
    if (self)
    {
        self.tableData = [NSMutableDictionary dictionary];
        self.tableSections = [NSMutableArray array];
        self.queryResults = [NSMutableArray array];
        
        self.searchQueue = [[[NSOperationQueue alloc] init] autorelease];
        [self.searchQueue setMaxConcurrentOperationCount:1];
        
        self.recentSearches = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"edu.mit.mobile.location.Recent"]];
        
        [self addSectionIdentifier:LocationSearchSectionQueryKey
                          withData:[NSMutableArray array]];
        self.allowsFreeTextEntry = NO;
        self.showRecentSearches = YES;
        
        UISearchBar *searchBar = [[[UISearchBar alloc] init] autorelease];
        searchBar.delegate = self;
        self.searchBar = searchBar;
        
        UISearchDisplayController *searchController = [[[UISearchDisplayController alloc] initWithSearchBar:searchBar
                                                                                         contentsController:contentsController] autorelease];
        searchController.delegate = self;
        searchController.searchResultsDelegate = self;
        searchController.searchResultsDataSource = self;
        self.searchDisplayController = searchController;
        
    }
    
    return self;
}

- (void)dealloc
{
    self.resultDelegate = nil;
    self.recentSearches = nil;
    self.tableData = nil;
    self.tableSections = nil;
    [super dealloc];
}

#pragma mark - Dynamic Properties
- (void)setQueryResults:(NSMutableArray *)queryResults
{
    [self setData:queryResults forSectionWithIdentifier:LocationSearchSectionQueryKey];
}

- (NSMutableArray*)queryResults
{
    return [self dataForSectionWithIdentifier:LocationSearchSectionQueryKey];
}

- (void)setFilteredRecentSearches:(NSArray *)filteredRecentSearches
{
    [self setData:filteredRecentSearches forSectionWithIdentifier:LocationSearchSectionRecentKey];
}

- (NSArray*)filteredRecentSearches
{
    return [self dataForSectionWithIdentifier:LocationSearchSectionRecentKey];
}

#pragma mark - Property Methods
- (void)setAllowsFreeTextEntry:(BOOL)allowsFreeTextEntry
{
    if (allowsFreeTextEntry)
    {
        
        [self insertSectionIdentifier:LocationSearchSectionAsEnteredKey
                             withData:[NSNull null]
                              atIndex:0];
    }
    else
    {
        [self hideSectionWithIdentifier:LocationSearchSectionAsEnteredKey];
    }
}

- (BOOL)allowsFreeTextEntry
{
    return [self isSectionVisible:LocationSearchSectionAsEnteredKey];
}

- (void)setShowRecentSearches:(BOOL)showRecentSearches
{
    if (showRecentSearches)
    {
        id data = self.filteredRecentSearches;
        if (data == nil)
        {
            data = self.recentSearches;
        }
        
        [self insertSectionIdentifier:LocationSearchSectionRecentKey
                             withData:data
                              atIndex:[self sectionIndexForIdentifier:LocationSearchSectionQueryKey]];
    }
    else
    {
        [self hideSectionWithIdentifier:LocationSearchSectionRecentKey];
    }
}

- (BOOL)showRecentSearches
{
    return [self isSectionVisible:LocationSearchSectionRecentKey];
}

#pragma mark - Private Methods
- (NSArray*)recentSearchesForQuery:(NSString*)query
{
    NSMutableArray *filtered = [NSMutableArray array];
    NSString *upperQuery = [query uppercaseString];
    
    NSArray* words = [upperQuery componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    upperQuery = [words componentsJoinedByString:@""];
    
    [self.recentSearches enumerateObjectsUsingBlock:^(NSString *result, NSUInteger idx, BOOL *stop) {
        NSArray* words = [[result uppercaseString] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *joinedResult = [words componentsJoinedByString:@""];
        
        BOOL prefixMatch = (([upperQuery length] == 0) || [joinedResult hasPrefix:upperQuery]);
        BOOL stringMatch = [joinedResult isEqualToString:upperQuery];
        if (prefixMatch && (stringMatch == NO))
        {
            [filtered addObject:result];
        }
    }];
    
    return filtered;
}

- (void)updateTableForQuery:(NSString*)query withResults:(NSSet*)newResults
{
    NSMutableSet *deletedObjects = [NSMutableSet set];
    NSMutableSet *addedObjects = [NSMutableSet set];
    NSMutableSet *updatedObjects = [NSMutableSet set];
    
    NSMutableSet *resultSet = [NSMutableSet setWithArray:self.queryResults];
    [resultSet unionSet:newResults];
    [resultSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        BOOL oldResult = [self.queryResults containsObject:obj];
        BOOL newResult = [newResults containsObject:obj];
        
        if (oldResult && newResult)
        {
            [updatedObjects addObject:obj];
        }
        else if (newResult)
        {
            [addedObjects addObject:obj];
        }
        else
        {
            [deletedObjects addObject:obj];
        }
    }];
    
    NSMutableArray *updatedResults = [NSMutableArray arrayWithArray:[newResults allObjects]];
    [updatedResults sortUsingComparator:[LocationSearchController queryResultsComparator]];
    
    NSMutableSet *deletedPaths = [NSMutableSet set];
    NSMutableSet *addedPaths = [NSMutableSet set];
           
    NSArray *newRecents = [self recentSearchesForQuery:query];
    if (([newRecents count] == 0) && self.showRecentSearches)
    {
        self.showRecentSearches = NO;
    }
    else if ([newRecents count])
    {
        if (self.showRecentSearches == NO)
        {
            self.showRecentSearches = YES;
        }
        
        NSUInteger recentSection = [self sectionIndexForIdentifier:LocationSearchSectionRecentKey];  
        [self.filteredRecentSearches enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([newRecents containsObject:obj] == NO)
            {
                [deletedPaths addObject:[NSIndexPath indexPathForRow:idx
                                                           inSection:recentSection]];
            }
        }];
        
        [newRecents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([self.filteredRecentSearches containsObject:obj] == NO)
            {
                [addedPaths addObject:[NSIndexPath indexPathForRow:idx
                                                         inSection:recentSection]];
            }
        }];
        
        self.filteredRecentSearches = newRecents;
    }
    
    NSUInteger querySection = [self sectionIndexForIdentifier:LocationSearchSectionQueryKey];
    
    [deletedObjects enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [deletedPaths addObject:[NSIndexPath indexPathForRow:[self.queryResults indexOfObject:obj]
                                                   inSection:querySection]];
    }];

    
    [addedObjects enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [addedPaths addObject:[NSIndexPath indexPathForRow:[updatedResults indexOfObject:obj]
                                                 inSection:querySection]];
    }];
    
    NSMutableSet *updatedPaths = [NSMutableSet setWithSet:addedPaths];
    [updatedPaths intersectSet:deletedPaths];
    
    if (self.allowsFreeTextEntry)
    {
        if ([self.queryString length] && ([query length] == 0))
        {
            [deletedPaths addObject:[NSIndexPath indexPathForRow:0
                                                       inSection:[self sectionIndexForIdentifier:LocationSearchSectionAsEnteredKey]]];
        }
        else if ([self.queryString length] == 0)
        {
            [addedPaths addObject:[NSIndexPath indexPathForRow:0
                                                     inSection:[self sectionIndexForIdentifier:LocationSearchSectionAsEnteredKey]]];
        }
        else
        {
            [updatedPaths addObject:[NSIndexPath indexPathForRow:0
                                                       inSection:[self sectionIndexForIdentifier:LocationSearchSectionAsEnteredKey]]];
        }
    }
    
    [addedPaths minusSet:updatedPaths];
    [deletedPaths minusSet:updatedPaths];
    
    self.queryResults = updatedResults;
    self.queryString = query;
    
    [[self tableView] beginUpdates];
    {
        [[self tableView] deleteRowsAtIndexPaths:[deletedPaths allObjects]
                                withRowAnimation:UITableViewRowAnimationFade];
        
        [[self tableView] insertRowsAtIndexPaths:[addedPaths allObjects]
                                withRowAnimation:UITableViewRowAnimationFade];
        
        [[self tableView] reloadRowsAtIndexPaths:[updatedPaths allObjects]
                                withRowAnimation:UITableViewRowAnimationFade];
    }
    [[self tableView] endUpdates];
}

- (void)locationResultsForQuery:(NSString*)query
{
    LocationSearchOperation *search = [[[LocationSearchOperation alloc] initWithQueryString:query forCategory:nil] autorelease];
    search.searchCompletedBlock = ^(NSSet *data, NSArray *autoComplete)
    {
        if ([self.pendingQueryString isEqualToString:query])
        {
            if (self.loadingView)
            {
                [self.loadingView removeFromSuperview];
                self.loadingView = nil;
            }
            
            [self updateTableForQuery:query
                          withResults:data];
        }
    };
    
    [self.searchQueue addOperation:search];
}

- (void)addStringToRecentSearches:(NSString *)string
{
    if ([self.recentSearches containsObject:string] == NO)
    {
        [self.recentSearches addObject:string];
        [[NSUserDefaults standardUserDefaults] setObject:self.recentSearches
                                                  forKey:@"edu.mit.mobile.location.Recent"];
    }
}

- (void)clearRecentSearches
{
    self.filteredRecentSearches = nil;
    self.recentSearches = nil;
    [[NSUserDefaults standardUserDefaults] setObject:self.recentSearches
                                              forKey:@"edu.mit.mobile.location.Recent"];
    
    NSUInteger recentIndex = [self sectionIndexForIdentifier:LocationSearchSectionRecentKey];
    if (recentIndex != NSNotFound)
    {
        [self.searchDisplayController.searchResultsTableView reloadSections:[NSIndexSet indexSetWithIndex:recentIndex]
                                                           withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Table Section Management
- (UITableView*)tableView
{
    return self.searchDisplayController.searchResultsTableView;
}
         
 - (void)hideSectionWithIdentifier:(NSString*)identifier
 {
     if ([self isSectionVisible:identifier])
     {
         NSInteger sectionIndex = [self sectionIndexForIdentifier:identifier];
         [self.tableSections removeObject:identifier];
         [[self tableView] deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                         withRowAnimation:UITableViewRowAnimationFade];
     }
 }

- (void)deleteSectionWithIdentifier:(NSString*)identifier
{
    if ([self isSectionVisible:identifier])
    {
        [self hideSectionWithIdentifier:identifier];
        [self.tableData removeObjectForKey:identifier];
    }
}

- (void)showSectionIdentifier:(NSString*)identifier
{
    [self insertSectionIdentifier:identifier
                      withData:[self dataForSectionWithIdentifier:identifier]
                       atIndex:[self.tableSections count]];
}

- (void)showSectionIdentifier:(NSString*)identifier
                      atIndex:(NSUInteger)index
{
    [self insertSectionIdentifier:identifier
                      withData:[self dataForSectionWithIdentifier:identifier]
                       atIndex:index];
}

- (void)addSectionIdentifier:(NSString*)identifier
                    withData:(id)data
{
    [self insertSectionIdentifier:identifier
                      withData:data
                       atIndex:[self.tableSections count]];
}
        
- (void)insertSectionIdentifier:(NSString*)identifier
                          withData:(id)data
                           atIndex:(NSUInteger)index
{
    if (index == NSNotFound)
    {
        index = 0;
    }
    
    if ([self isSectionVisible:identifier] == NO)
    {
        [self setData:data forSectionWithIdentifier:identifier];
        [self.tableSections insertObject:identifier
                                 atIndex:index];
        [[self tableView] insertSections:[NSIndexSet indexSetWithIndex:index]
                        withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (BOOL)isSectionVisible:(NSString*)identifier
{
    return [self.tableSections containsObject:identifier];
}

- (id)dataForSectionWithIdentifier:(NSString*)identifier
{
    return [self.tableData objectForKey:identifier];
}

- (void)setData:(id)data forSectionWithIdentifier:(NSString*)identifier
{
    [self.tableData setObject:data
                       forKey:identifier];
}

- (NSString*)identifierForSectionIndex:(NSInteger)section
{
    return [self.tableSections objectAtIndex:section];
}

- (NSInteger)sectionIndexForIdentifier:(NSString*)identifier
{
    return [self.tableSections indexOfObject:identifier];
}

#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *sectionIdentifier = [self identifierForSectionIndex:indexPath.section];
    
    if ([sectionIdentifier isEqualToString:LocationSearchSectionAsEnteredKey])
    {
        [self addStringToRecentSearches:self.queryString];
        
        if ([self.resultDelegate respondsToSelector:@selector(locationSearch:didFinishWithSearchString:)])
        {
            [self.resultDelegate locationSearch:self
                      didFinishWithSearchString:self.queryString];
        }
        
        [self.searchDisplayController setActive:NO
                                       animated:YES];
    }
    else if ([sectionIdentifier isEqualToString:LocationSearchSectionRecentKey])
    {
        self.queryString = [self.filteredRecentSearches objectAtIndex:indexPath.row];
        self.searchBar.text = self.queryString;
    }
    else if ([sectionIdentifier isEqualToString:LocationSearchSectionQueryKey])
    {
        [self addStringToRecentSearches:self.queryString];
        
        if ([self.resultDelegate respondsToSelector:@selector(locationSearch:didFinishWithResult:)])
        {
            NSDictionary *dict = [self.queryResults objectAtIndex:indexPath.row];
            NSManagedObjectID *locationID = (NSManagedObjectID*)[dict objectForKey:LocationSearchResultObjectIDKey];
            FacilitiesLocation *location = (FacilitiesLocation*)[[[CoreDataManager coreDataManager] managedObjectContext] objectWithID:locationID];
            
            [self.resultDelegate locationSearch:self
                            didFinishWithResult:location];
        }
        
        [self.searchDisplayController setActive:NO
                                       animated:YES];
    }

    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.tableSections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = 0;
    NSString *sectionIdentifier = [self identifierForSectionIndex:section];
    id data = [self dataForSectionWithIdentifier:sectionIdentifier];
    
    if ([self isSectionVisible:sectionIdentifier] == NO)
    {
        count = 0;
    }
    else if ([data respondsToSelector:@selector(count)])
    {
        count = [data count];
    }
    else if ([sectionIdentifier isEqualToString:LocationSearchSectionAsEnteredKey])
    {
        count = ([self.queryString length] ? 1 : 0);
    }
    else
    {
        count = (data == nil) ? 0 : 1;
    }
    
    return count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *titleString = nil;
    NSString *sectionIdentifier = [self identifierForSectionIndex:section];
    
    if ([sectionIdentifier isEqualToString:LocationSearchSectionAsEnteredKey])
    {
        titleString = @"Use As Entered";
    }
    else if ([sectionIdentifier isEqualToString:LocationSearchSectionRecentKey])
    {
        titleString = @"Recent Searches";
    }
    else if ([sectionIdentifier isEqualToString:LocationSearchSectionQueryKey])
    {
        titleString = @"Search Results";
    }
    
    return titleString;
}

- (NSString*)cellIdentifierForSection:(NSUInteger)index
{
    return [self identifierForSectionIndex:index];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *sectionIdentifier = [self identifierForSectionIndex:indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sectionIdentifier];
    
    if ([sectionIdentifier isEqualToString:LocationSearchSectionAsEnteredKey])
    {
        if (cell == nil)
        {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:sectionIdentifier] autorelease];
        }

        cell.textLabel.text = [NSString stringWithFormat:@"Search for '%@'", self.queryString];
    }
    else if ([sectionIdentifier isEqualToString:LocationSearchSectionRecentKey])
    {
        if (cell == nil)
        {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:sectionIdentifier] autorelease];
        }
        
        cell.textLabel.text = [self.filteredRecentSearches objectAtIndex:indexPath.row];
    }
    else if ([sectionIdentifier isEqualToString:LocationSearchSectionQueryKey])
    {
        if (cell == nil)
        {
            cell = [[[HighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                  reuseIdentifier:sectionIdentifier] autorelease];
        }
        
        HighlightTableViewCell *hlCell = (HighlightTableViewCell*)cell;
        NSString *labelString = hlCell.highlightLabel.searchString;
        if ([labelString isEqualToString:self.queryString] == NO)
        {
            hlCell.highlightLabel.searchString = self.queryString;
        }
        
        NSDictionary *loc = [self.queryResults objectAtIndex:indexPath.row];
        hlCell.highlightLabel.text = [loc objectForKey:LocationSearchResultDisplayStringKey];
    }
    
    return cell;
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSString *trimmedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![self.queryString isEqualToString:trimmedString]) {
        NSString *newQuery = ([trimmedString length] > 0) ? trimmedString : @"";
        
        [self.searchQueue cancelAllOperations];
        self.pendingQueryString = newQuery;
        [self locationResultsForQuery:newQuery];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchDisplayController setActive:NO
                                   animated:YES];
}

#pragma mark - UISearchDisplayControllerDelegate
- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateKeyboardFrame:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateKeyboardFrame:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView
{
    // Make sure tapping the status bar always scrolls to the top of the active table
    tableView.scrollsToTop = YES;
    
    if (self.loadingView == nil) 
    {
        CGRect frame = tableView.frame;
        frame.size.height = CGRectGetHeight(tableView.frame) - CGRectGetHeight(_keyboardFrame);
        
        self.loadingView = [[[MITLoadingActivityView alloc] initWithFrame:frame] autorelease];
        self.loadingView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                             UIViewAutoresizingFlexibleWidth);
        [self.loadingView setBackgroundColor:[UIColor grayColor]];
        [tableView.superview addSubview:self.loadingView];
    }
}


- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification 
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification 
                                                  object:nil];
}

- (void)updateKeyboardFrame:(NSNotification*)notification
{
    NSValue *value = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    _keyboardFrame = [value CGRectValue];
}
@end
