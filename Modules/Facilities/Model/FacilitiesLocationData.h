#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "MITMobileWebAPI.h"

typedef void (^LocationResultBlock)(NSSet *objectIDs, NSError *error);

@class FacilitiesLocation;

@interface FacilitiesLocationData : NSObject

+ (FacilitiesLocationData*)sharedData;
- (id)init;

#pragma mark -
// All of the resultBlock arguments in the below methods
//  will be invoked on the main queue when the operation is
//  complete. Be sure to avoid performing any long running
//  tasks in the callbacks to avoid locking up the UI

- (void)allCategories:(LocationResultBlock)resultBlock;
- (void)allLocations:(LocationResultBlock)resultBlock;
- (void)locationsInCategory:(NSString*)categoryId
           requestCompleted:(LocationResultBlock)resultBlock;
- (void)roomsForBuilding:(NSString*)bldgnum
        requestCompleted:(LocationResultBlock)resultBlock;
- (void)hiddenBuildings:(LocationResultBlock)resultBlock;
- (void)leasedBuildings:(LocationResultBlock)resultBlock;
- (void)allRepairTypes:(LocationResultBlock)resultBlock;
@end
