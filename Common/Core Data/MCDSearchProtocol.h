#import <UIKit/UIKit.h>

typedef enum {
    MCDSearchTypeUnsupported = 0,
    MCDSearchTypeLocation = 1
} MCDSearchType;

@protocol MCDSearchProtocol <NSObject>
+ (MCDSearchType)supportedSearchTypes;
+ (NSString*)searchSectionTitle;
+ (NSSet*)resultsForQuery:(NSString*)query options:(NSDictionary*)searchOptions;
+ (NSArray*)autocompleteSuggestionsForQuery:(NSString*)query;

- (NSDictionary*)searchEntityWithQuery:(NSString*)query;
- (UITableViewCell*)cellWithQueryInfo:(NSDictionary*)queryInfo forTableView:(UITableView*)tableView;
@end
