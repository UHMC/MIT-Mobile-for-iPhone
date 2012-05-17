#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class MGSMapCoordinate;

@interface MGSMapAnnotation : NSObject
@property (nonatomic, strong) MGSMapCoordinate *coordinate;

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *detail;
@property (nonatomic, strong) UIImage *image;

- (id)initWithTitle:(NSString*)title
         detailText:(NSString*)detail
       atCoordinate:(MGSMapCoordinate*)coordinate;
@end
