#import "LocationSearchOperation.h"

#import "FacilitiesLocationData.h"
#import "FacilitiesCategory.h"
#import "FacilitiesLocation.h"
#import "FacilitiesContent.h"
#import "Foundation+MITAdditions.h"
#import "CoreDataManager.h"

NSString * const LocationSearchResultObjectIDKey = @"LocationSearchResultObjectID";
NSString * const LocationSearchResultDisplayStringKey = @"LocationSearchResultDisplayString";
NSString * const LocationSearchResultMatchTypeKey = @"LocationSearchResultMatchType";
NSString * const LocationSearchResultMatchObjectKey = @"LocationSearchResultMatchObject";

NSString * const LocationMatchTypeLocationNameOrNumber = @"LocationMatchTypeLocationNameOrNumber";
NSString * const LocationMatchTypeLocationCategory = @"LocationMatchTypeLocationCategory";
NSString * const LocationMatchTypeContentName = @"LocationMatchTypeContentName";
NSString * const LocationMatchTypeContentCategory = @"LocationMatchTypeContentCategory";

static inline NSString* NSStringFromBOOL(BOOL aBool)
{
    return (aBool ? @"YES" : @"NO");
}

@interface LocationSearchOperation ()
@property (nonatomic,strong) NSString *queryString;
@property (nonatomic,strong) NSString *categoryUid;
@property (nonatomic,assign) dispatch_queue_t queue;
@property (getter=isSearching) BOOL searching;

- (void)performSearch;
- (NSDictionary*)searchNameAndNumberForLocation:(FacilitiesLocation*)location
                                   forSubstring:(NSString*)substring;
- (NSDictionary*)searchCategoriesForLocation:(FacilitiesLocation*)location
                                forSubstring:(NSString*)substring;
- (NSDictionary*)searchContentForLocation:(FacilitiesLocation*)location
                             forSubstring:(NSString*)substring;
@end

@implementation LocationSearchOperation
@synthesize queryString = _queryString;
@synthesize categoryUid = _categoryUid;
@synthesize queue = _queue;

@synthesize searching = _searching;

@synthesize searchesCategories = _searchesCategories;
@synthesize showHiddenBuildings = _showHiddenBuildings;
@synthesize searchCompletedBlock = _searchCompletedBlock;

+ (id)searchOperationWithQueryString:(NSString*)queryString
                         forCategory:(FacilitiesCategory*)category
{
    LocationSearchOperation *operation = [[self alloc] initWithQueryString:queryString
                                                               forCategory:category];
    
    return [operation autorelease];
}

- (id)initWithQueryString:(NSString*)queryString
              forCategory:(FacilitiesCategory*)category
{
    self = [super init];
    if (self)
    {
        self.queryString = [queryString length] ? queryString : @"";
        self.categoryUid = category.uid;
    }
    
    return self;
}

- (void)dealloc
{
    self.searchCompletedBlock = nil;
    self.queryString = nil;
    self.categoryUid = nil;
    self.queue = nil;
    [super dealloc];
}

#pragma mark - NSOperation
- (void)main
{
    self.queue = dispatch_get_current_queue();
    
    if ([self isCancelled] == NO)
    {
        [self performSearch];
        
        while ([self isSearching] && ([self isCancelled] == NO))
        {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate distantFuture]];
        }
    }
}

- (BOOL)isConcurrent
{
    return NO;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]])
    {
        LocationSearchOperation *op = (LocationSearchOperation*)object;
        
        return ([op.queryString isEqualToString:self.queryString] &&
                [op.categoryUid isEqualToString:self.categoryUid]);
    }
    
    return NO;
}

#pragma mark - Private Methods
- (void)performSearch
{
    FacilitiesLocationData *fld = [FacilitiesLocationData sharedData];
    NSString *queryString = [self.queryString length] ? [NSString stringWithString:self.queryString] : @"";
    NSString *cuid = [[self.categoryUid copy] autorelease];
    self.searching = YES;
    
    void (^searchBlock)(NSSet*) = ^(NSSet* objectIDs) {
        NSMutableArray *locations = [NSMutableArray array];
        [locations addObjectsFromArray:[[[CoreDataManager coreDataManager] objectsForObjectIDs:objectIDs] allObjects]];
        
        if (cuid)
        {
            [locations filterUsingPredicate:[NSPredicate predicateWithFormat:@"ANY categories.uid == %@", cuid]];
        }
        
        if (self.showHiddenBuildings == NO)
        {
            [locations filterUsingPredicate:[NSPredicate predicateWithFormat:@"isLeased == NO"]];
        }
        
        NSMutableSet *matchedLocations = [NSMutableSet set];
        NSMutableSet *searchResults = [NSMutableSet set];
        
        [locations enumerateObjectsUsingBlock:^(FacilitiesLocation *location, NSUInteger idx, BOOL *stop) {
            if ([self isCancelled])
            {
                (*stop) = YES;
            }
            else if ([matchedLocations containsObject:location] == NO)
            {
                NSDictionary *matchResult = [self searchNameAndNumberForLocation:location
                                                                    forSubstring:queryString];
                if (matchResult)
                {
                    [searchResults addObject:matchResult];
                    [matchedLocations addObject:[matchResult objectForKey:LocationSearchResultObjectIDKey]];
                }
                else
                {
                    if (self.searchesCategories)
                    {
                        // Check for any matching categories
                        matchResult = [self searchCategoriesForLocation:location
                                                           forSubstring:queryString];
                        if (matchResult)
                        {
                            [searchResults addObject:matchResult];
                            [matchedLocations addObject:[matchResult objectForKey:LocationSearchResultObjectIDKey]];
                            return;
                        }
                    }
                    
                    // Still nothing, check the contents
                    matchResult = [self searchContentForLocation:location
                                                    forSubstring:queryString];
                    if (matchResult) {
                        [searchResults addObject:matchResult];
                        [matchedLocations addObject:[matchResult objectForKey:LocationSearchResultObjectIDKey]];
                    }
                }
            }
        }];
        
        if (self.searchCompletedBlock && ([self isCancelled] == NO))
        {
            NSMutableSet *results = [NSMutableSet setWithCapacity:[searchResults count]];
            [searchResults enumerateObjectsUsingBlock:^(NSManagedObject *mo, BOOL *stop) {
                [results addObject:mo];
            }];
            [self performBlockOnMainThread:^{ self.searchCompletedBlock(results,nil); }
                             waitUntilDone:NO];
        }
        
        self.searching = NO;
    };
    
    [fld allLocations:^(NSSet *objectIDs, NSError *error) {
        if ([self isCancelled] == NO)
        {
            dispatch_async(self.queue, ^{ searchBlock(objectIDs); });
        }
    }];
}

- (NSDictionary*)searchNameAndNumberForLocation:(FacilitiesLocation*)location forSubstring:(NSString*)substring {
    BOOL contains = [[location displayString] containsSubstring:substring
                                                        options:NSCaseInsensitiveSearch];
    if (contains)
    {
        NSMutableDictionary *matchData = [NSMutableDictionary dictionary];
        [matchData setObject:[location objectID]
                      forKey:LocationSearchResultObjectIDKey];
        [matchData setObject:[location displayString]
                      forKey:LocationSearchResultDisplayStringKey];
        [matchData setObject:LocationMatchTypeLocationNameOrNumber
                      forKey:LocationSearchResultMatchTypeKey];
        return [NSDictionary dictionaryWithDictionary:matchData];
    }
    
    return nil;
}

- (NSDictionary*)searchCategoriesForLocation:(FacilitiesLocation*)location forSubstring:(NSString*)substring {
    for (FacilitiesCategory *category in location.categories) {
        if ([category.name containsSubstring:substring options:NSCaseInsensitiveSearch]) {
            NSMutableDictionary *matchData = [NSMutableDictionary dictionary];
            [matchData setObject:[location objectID]
                          forKey:LocationSearchResultObjectIDKey];
            
            [matchData setObject:[location displayString]
                          forKey:LocationSearchResultDisplayStringKey];
            [matchData setObject:LocationMatchTypeLocationCategory
                          forKey:LocationSearchResultMatchTypeKey];
            [matchData setObject:category
                          forKey:LocationSearchResultMatchObjectKey];
            return [NSDictionary dictionaryWithDictionary:matchData];
        }
    }
    
    return nil;
}

- (NSDictionary*)searchContentForLocation:(FacilitiesLocation*)location forSubstring:(NSString*)substring {
    NSMutableSet *names = [NSMutableSet setWithCapacity:1];
    
    for (FacilitiesContent *content in location.contents) {
        [names removeAllObjects];
        [names addObject:content.name];
        [names addObjectsFromArray:content.altname];
        
        for (NSString *name in names) {
            NSRange substrRange = [name rangeOfString:substring
                                              options:NSCaseInsensitiveSearch];
            
            if (substrRange.location != NSNotFound) {
                NSMutableDictionary *matchData = [NSMutableDictionary dictionary];
                [matchData setObject:[location objectID]
                              forKey:LocationSearchResultObjectIDKey];
                
                NSString *displayString = nil;
                if (location.number && ([location.number length] > 0)) {
                    displayString = [NSString stringWithFormat:@"%@ (%@)",location.number,name];
                } else {
                    displayString = [NSString stringWithFormat:@"%@ (%@)",location.name,name];
                }
                [matchData setObject:displayString
                              forKey:LocationSearchResultDisplayStringKey];
                [matchData setObject:LocationMatchTypeContentName
                              forKey:LocationSearchResultMatchTypeKey];
                [matchData setObject:content
                              forKey:LocationSearchResultMatchObjectKey];
                return [NSDictionary dictionaryWithDictionary:matchData];
            }
        }
        
        
        if (self.searchesCategories && ([content.categories count] > 0)) {
            for (FacilitiesCategory *category in content.categories) {
                NSRange substrRange = [category.name rangeOfString:substring
                                                           options:NSCaseInsensitiveSearch];
                
                if (substrRange.location != NSNotFound) {
                    NSMutableDictionary *matchData = [NSMutableDictionary dictionary];
                    [matchData setObject:[location objectID]
                                  forKey:LocationSearchResultObjectIDKey];
                    
                    [matchData setObject:[location displayString]
                                  forKey:LocationSearchResultDisplayStringKey];
                    [matchData setObject:LocationMatchTypeContentCategory
                                  forKey:LocationSearchResultMatchTypeKey];
                    [matchData setObject:category
                                  forKey:LocationSearchResultMatchObjectKey];
                    return [NSDictionary dictionaryWithDictionary:matchData];
                }
            }
        }
    }
    
    return nil;
}
@end
