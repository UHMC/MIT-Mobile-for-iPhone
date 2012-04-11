#import <Foundation/Foundation.h>

extern NSString * const LocationSearchResultObjectIDKey;
extern NSString * const LocationSearchResultDisplayStringKey;
extern NSString * const LocationSearchResultMatchTypeKey;
extern NSString * const LocationSearchResultMatchObjectKey;

extern NSString * const LocationMatchTypeLocationNameOrNumber;
extern NSString * const LocationMatchTypeLocationCategory;
extern NSString * const LocationMatchTypeContentName;
extern NSString * const LocationMatchTypeContentCategory;

@class FacilitiesCategory;

@interface LocationSearchOperation : NSOperation

@property (nonatomic, copy) void (^searchCompletedBlock)(NSSet *searchResults, NSArray *autocompleteResults);
@property (nonatomic) BOOL searchesCategories;
@property (nonatomic) BOOL showHiddenBuildings;

+ (id)searchOperationWithQueryString:(NSString*)queryString forCategory:(FacilitiesCategory*)category;
- (id)initWithQueryString:(NSString*)queryString forCategory:(FacilitiesCategory*)category;
@end
