#import <CoreData/CoreData.h>
#import "LocationSearchController.h"
#import "CoreDataManager.h"
#import "FacilitiesLocationSearch.h"
#import "Foundation+MITAdditions.h"
#import "HighlightTableViewCell.h"

enum {
    LocationSearchSectionAsEntered = 0,
    LocationSearchSectionRecent,
    LocationSearchSectionQuery
};

@interface LocationSearchController ()
@property (nonatomic,strong) UISearchDisplayController *searchDisplayController;
@property (nonatomic,strong) UIViewController *contentsController;
@property (nonatomic,strong) UISearchBar *searchBar;
@property (nonatomic,strong) NSString *searchString;
@property (nonatomic,strong) NSArray *queryResults;

@property (nonatomic,strong) NSMutableArray *recentSearches;
@property (nonatomic,strong) NSArray *filteredRecentSearches;

@property (nonatomic,strong) FacilitiesLocationSearch *searchHelper;
@property (nonatomic,strong) NSMutableIndexSet *visibleSections;

- (void)addStringToRecentSearches:(NSString*)string;
@end

@implementation LocationSearchController
@synthesize resultDelegate = _resultDelegate;
@synthesize queryResults = _queryResults;
@synthesize recentSearches = _allRecentSearches;
@synthesize searchHelper = _searchHelper;
@synthesize visibleSections = _visibleSections;
@synthesize filteredRecentSearches = _filteredRecentSearches;
@synthesize searchString = _searchString;
@synthesize searchDisplayController = _searchDisplayController;
@synthesize contentsController = _contentsController;
@synthesize searchBar = _searchBar;

@dynamic allowsFreeTextEntry;
@dynamic showRecentSearches;

- (id)initWithContentsController:(UIViewController *)contentsController
{
    self = [super init];
    if (self)
    {
        self.recentSearches = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"edu.mit.mobile.location.Recent"]];
        
        self.visibleSections = [NSMutableIndexSet indexSet];
        [self.visibleSections addIndex:LocationSearchSectionAsEntered];
        [self.visibleSections addIndex:LocationSearchSectionRecent];
        [self.visibleSections addIndex:LocationSearchSectionQuery];
        
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
    self.queryResults = nil;
    self.recentSearches = nil;
    self.searchHelper = nil;
    self.visibleSections = nil;
    self.filteredRecentSearches = nil;
    self.searchString = nil;
    [super dealloc];
}

#pragma mark - Property Methods
- (NSArray*)queryResults
{
    if (_queryResults == nil)
    {
        self.queryResults = [self locationResultsForQuery:self.searchString];
    }
    
    return _queryResults;
}

- (NSArray*)filteredRecentSearches
{
    if (_filteredRecentSearches == nil)
    {
        self.filteredRecentSearches = [self recentSearchesForQuery:self.searchString];
    }
    
    return _filteredRecentSearches;
}

- (void)setAllowsFreeTextEntry:(BOOL)allowsFreeTextEntry
{
    if (allowsFreeTextEntry)
    {
        [self.visibleSections addIndex:LocationSearchSectionAsEntered];
    }
    else
    {
        [self.visibleSections removeIndex:LocationSearchSectionAsEntered];
    }
    
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (BOOL)allowsFreeTextEntry
{
    return [self.visibleSections containsIndex:LocationSearchSectionAsEntered];
}

- (void)setShowRecentSearches:(BOOL)showRecentSearches
{
    if (showRecentSearches)
    {
        [self.visibleSections addIndex:LocationSearchSectionRecent];
    }
    else
    {
        [self.visibleSections removeIndex:LocationSearchSectionRecent];
    }
    
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (BOOL)showRecentSearches
{
    return [self.visibleSections containsIndex:LocationSearchSectionRecent];
}

#pragma mark - Private Methods
- (NSArray*)recentSearchesForQuery:(NSString*)query
{
    NSMutableArray *filtered = [NSMutableArray array];
    NSString *upperQuery = [query uppercaseString];
    
    NSArray* words = [upperQuery componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    upperQuery = [words componentsJoinedByString:@""];
    
    [self.recentSearches enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *result = [(NSString*)obj uppercaseString];
        NSArray* words = [result componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        result = [words componentsJoinedByString:@""];
        
        BOOL prefixMatch = (([upperQuery length] == 0) || [result hasPrefix:upperQuery]);
        BOOL stringMatch = [result isEqualToString:upperQuery];
        if (prefixMatch && (stringMatch == NO))
        {
            [filtered addObject:obj];
        }
    }];
    
    return filtered;
}

- (NSArray*)locationResultsForQuery:(NSString*)query
{
    if (self.searchHelper == nil) {
        self.searchHelper = [[[FacilitiesLocationSearch alloc] init] autorelease];
    }
    
    self.searchHelper.category = nil;
    self.searchHelper.searchString = query;
    NSArray *results = [self.searchHelper searchResults];
    
    NSLog(@"Found %d results from 'locations'", [results count]);
    
    results = [results sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *key1 = [obj1 valueForKey:FacilitiesSearchResultDisplayStringKey];
        NSString *key2 = [obj2 valueForKey:FacilitiesSearchResultDisplayStringKey];
        
        return [key1 compare:key2
                     options:(NSCaseInsensitiveSearch |
                              NSNumericSearch |
                              NSForcedOrderingSearch)];
    }];
    
    return results;
}

- (NSUInteger)sectionForTableViewSection:(NSInteger)tableSection
{
    __block NSUInteger count = tableSection;
    __block NSUInteger index = NSNotFound;
    
    [self.visibleSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (count == 0)
        {
            index = idx;
            (*stop) = YES;
        }
        else
        {
            --count;
        }
    }];
    
    return index;
}

- (void)addStringToRecentSearches:(NSString *)string
{
    if ([self.recentSearches containsObject:string] == NO)
    {
        self.filteredRecentSearches = nil;
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
}

#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger section = [self sectionForTableViewSection:indexPath.section];
    
    switch (section)
    {
        case LocationSearchSectionAsEntered:
        {
            [self addStringToRecentSearches:self.searchString];
            
            if ([self.resultDelegate respondsToSelector:@selector(locationSearch:didFinishWithSearchString:)])
            {
                [self.resultDelegate locationSearch:self
                          didFinishWithSearchString:self.searchString];
            }
            
            [self.searchDisplayController setActive:NO
                                           animated:YES];
            break;
        }
            
        case LocationSearchSectionRecent:
        {
            self.searchString = [self.filteredRecentSearches objectAtIndex:indexPath.row];
            self.searchBar.text = self.searchString;
            break;
        }
            
        case LocationSearchSectionQuery:
        {
            [self addStringToRecentSearches:self.searchString];
            
            if ([self.resultDelegate respondsToSelector:@selector(locationSearch:didFinishWithResult:)])
            {
                NSDictionary *dict = [self.queryResults objectAtIndex:indexPath.row];
                FacilitiesLocation *location = (FacilitiesLocation*)[dict objectForKey:FacilitiesSearchResultLocationKey];
                [self.resultDelegate locationSearch:self
                                didFinishWithResult:location];
            }
            
            [self.searchDisplayController setActive:NO
                                           animated:YES];
            break;
        }
        
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sectionCount = [self.visibleSections count];
    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger index = [self sectionForTableViewSection:section];
    NSInteger count = 0;
    
    switch (index)
    {
        case LocationSearchSectionAsEntered:
            count = ([self.searchString length] > 0) ? 1 : 0;
            break;
            
        case LocationSearchSectionRecent:
            count = [self.filteredRecentSearches count];
            break;
            
        case LocationSearchSectionQuery:
            count = [self.queryResults count];
            break;
    }
    
    NSLog(@"%d rows in section %d", count, index);
    return count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSUInteger index = [self sectionForTableViewSection:section];
    NSString *titleString = nil;
    
    switch (index)
    {
        case LocationSearchSectionAsEntered:
        {
            titleString = ([self.searchString length] > 0) ? @"Use As Entered" : nil;
            break;
        }
            
        case LocationSearchSectionRecent:
        {
            titleString = ([self.filteredRecentSearches count] > 0) ? @"Recent Searches" : nil;
            break;
        }
            
        case LocationSearchSectionQuery:
        {
            titleString = ([self.queryResults count] > 0) ? @"Search Results" : nil;
            break;
        }
    }
    
    return titleString;
}

- (NSString*)cellIdentifierForSection:(NSUInteger)index
{
    switch(index)
    {
        case LocationSearchSectionAsEntered:
            return @"edu.mit.mobile.location.asEnteredCell";
            
        case LocationSearchSectionRecent:
            return @"edu.mit.mobile.location.recentSearchesCell";
            
        case LocationSearchSectionQuery:
            return @"edu.mit.mobile.location.resultsCell";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger section = [self sectionForTableViewSection:indexPath.section];
    
    NSString *cellIdentifier = [self cellIdentifierForSection:section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    switch(section)
    {
        case LocationSearchSectionAsEntered:
        {
            if (cell == nil)
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:cellIdentifier] autorelease];
            }
            
            cell.textLabel.text = [NSString stringWithFormat:@"Search for '%@'", self.searchString];
            break;
        }
            
        case LocationSearchSectionRecent:
        {
            if (cell == nil)
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:cellIdentifier] autorelease];
            }
            
            cell.textLabel.text = [self.filteredRecentSearches objectAtIndex:indexPath.row];
            break;
        }
            
        case LocationSearchSectionQuery:
        {
            if (cell == nil)
            {
                cell = [[[HighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                      reuseIdentifier:cellIdentifier] autorelease];
            }
            
            HighlightTableViewCell *hlCell = (HighlightTableViewCell*)cell;
            NSString *labelString = hlCell.highlightLabel.searchString;
            if ([labelString isEqualToString:self.searchString] == NO)
            {
                hlCell.highlightLabel.searchString = self.searchString;
            }
            
            NSDictionary *loc = [self.queryResults objectAtIndex:indexPath.row];
            hlCell.highlightLabel.text = [loc objectForKey:FacilitiesSearchResultDisplayStringKey];
            
            break;
        }
    }
    
    return cell;
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSString *trimmedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![self.searchString isEqualToString:trimmedString]) {
        self.searchString = ([trimmedString length] > 0) ? trimmedString : nil;
        self.queryResults = nil;
        self.filteredRecentSearches = nil;
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchDisplayController setActive:NO
                                   animated:YES];
}

#pragma mark - UISearchDisplayControllerDelegate
- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView
{
    tableView.scrollsToTop = YES;
}

// Make sure tapping the status bar always scrolls to the top of the active table
- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView
{
    
}

@end
