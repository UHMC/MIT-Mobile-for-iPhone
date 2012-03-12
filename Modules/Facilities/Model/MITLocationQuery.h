#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "MITMobileWebAPI.h"

extern NSString* const FacilitiesDidLoadDataNotification;
extern NSString* const FacilitiesCategoriesKey;
extern NSString* const FacilitiesLocationsKey;
extern NSString* const FacilitiesRoomsKey;
extern NSString* const FacilitiesRepairTypesKey;

@interface MITLocationQuery : NSObject
typedef void (^FacilitiesDidLoadBlock)(NSString *name, BOOL dataUpdated, id userData);
typedef void (^LocationResultBlock)(NSSet *result);
+ (MITLocationQuery*)sharedData;

- (id)init;

- (void)allCategories:(LocationResultBlock)resultBlock;

- (void)allLocations:(LocationResultBlock)resultBlock;
- (void)locationsInCategory:(NSString*)categoryId onResultLoad:(LocationResultBlock)resultBlock;
- (void)locationsWithinRadius:(CLLocationDistance)radiusInMeters
                       ofLocation:(CLLocation*)location
                     withCategory:(NSString*)categoryId
                     onResultLoad:(LocationResultBlock)resultBlock;

- (void)roomsForBuilding:(NSString*)bldgnum
                onResultLoad:(LocationResultBlock)resultBlock;
- (void)roomsMatchingPredicate:(NSPredicate*)predicate
                      onResultLoad:(LocationResultBlock)resultBlock;

- (void)hiddenBuildings:(LocationResultBlock)resultBlock;
- (void)leasedBuildings:(LocationResultBlock)resultBlock;

- (void)allRepairTypes:(LocationResultBlock)resultBlock;
@end
