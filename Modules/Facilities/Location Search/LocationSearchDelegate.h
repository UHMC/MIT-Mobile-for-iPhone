#import <Foundation/Foundation.h>

@class LocationSearchController;
@class FacilitiesLocation;

@protocol LocationSearchDelegate <NSObject>
- (void)locationSearch:(LocationSearchController*)controller didFailWithError:(NSError*)error;
- (void)locationSearch:(LocationSearchController*)controller didFinishWithSearchString:(NSString*)string;
- (void)locationSearch:(LocationSearchController*)controller didFinishWithResult:(FacilitiesLocation*)location;
@end
