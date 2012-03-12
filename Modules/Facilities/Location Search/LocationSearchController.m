#import <CoreData/CoreData.h>
#import "LocationSearchController.h"
#import "CoreDataManager.h"
#import "FacilitiesLocationSearch.h"
#import "Foundation+MITAdditions.h"

enum {
    LocationSearchSectionAsEntered,
    LocationSearchSectionRecent,
    LocationSearchSectionQuery
};

@interface LocationSearchController ()
@property (nonatomic,strong) NSString *searchString;
@property (nonatomic,strong) NSArray *queryResults;
@end

@implementation LocationSearchController
@synthesize resultDelegate = _resultDelegate;
@synthesize queryResults = _queryResults;

- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self)
    {
        
    }
    
    return self;
}

- (void)dealloc
{
    self.searchString = nil;
    self.queryResults = nil;
    [super dealloc];
}

#pragma mark - Private Methods
- (NSArray*)recentSearchesForQuery:(NSString*)query
{
    NSArray *recentResults = [[NSUserDefaults standardUserDefaults] arrayForKey:@"edu.mit.mobile.location.Recent"];
    NSMutableArray *filters = [NSMutableArray array];
    
    [recentResults enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *result = obj;
        
        
    }];
}

- (NSArray*)locationResultsForQuery:(NSString*)query
{
    
}

#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section)
    {
        case LocationSearchSectionAsEntered:
        {
            if ([self.resultDelegate respondsToSelector:@selector(locationSearch:didFinishWithSearchString:)])
            {
                [self.resultDelegate locationSearch:self
                          didFinishWithSearchString:self.searchString];
            }
            break;
        }
            
        case LocationSearchSectionRecent:
        {
            
            break;
        }
            
        case LocationSearchSectionQuery:
        {
            if ([self.resultDelegate respondsToSelector:@selector(locationSearch:didFinishWithResult:)])
            {
                NSDictionary *dict = [self.queryResults objectAtIndex:indexPath.row];
                FacilitiesLocation *location = (FacilitiesLocation*)[dict objectForKey:FacilitiesSearchResultLocationKey];
                [self.resultDelegate locationSearch:self
                                didFinishWithResult:location];
            }
            break;
        }
        
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // The query se
    NSUInteger sectionCount = 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return ((section == 0) && [self shouldShowLocationSection]) ? 1 : [self.cachedData count];
    } else {
        return ([self.trimmedString length] > 0) ? [self.filteredData count] + 1 : 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *facilitiesIdentifier = @"facilitiesCell";
    static NSString *searchIdentifier = @"searchCell"; 
    
    if (tableView == self.tableView) {
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
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        HighlightTableViewCell *hlCell = nil;
        hlCell = (HighlightTableViewCell*)[tableView dequeueReusableCellWithIdentifier:searchIdentifier];
        
        if (hlCell == nil) {
            hlCell = [[[HighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                    reuseIdentifier:searchIdentifier] autorelease];
            
            hlCell.autoresizesSubviews = YES;
            hlCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        if (indexPath.row == 0) {
            hlCell.highlightLabel.searchString = nil;
            hlCell.highlightLabel.text = [NSString stringWithFormat:@"Use \"%@\"",self.searchString];
        } else {
            NSIndexPath *path = [NSIndexPath indexPathForRow:(indexPath.row-1)
                                                   inSection:indexPath.section];
            [self configureSearchCell:hlCell
                         forIndexPath:path];
        }
        
        
        return hlCell;
    } else {
        return nil;
    }
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.trimmedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![self.searchString isEqualToString:self.trimmedString]) {
        self.searchString = ([self.trimmedString length] > 0) ? self.trimmedString : nil;
        self.filteredData = nil;
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchDisplayController setActive:NO
                                   animated:YES];
}

#pragma mark - UISearchDisplayControllerDelegate
// Make sure tapping the status bar always scrolls to the top of the active table
- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
    self.tableView.scrollsToTop = NO;
    tableView.scrollsToTop = YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView {
    // using willUnload because willHide strangely doesn't get called when the "Cancel" button is clicked
    tableView.scrollsToTop = NO;
    self.tableView.scrollsToTop = YES;
}

@end
