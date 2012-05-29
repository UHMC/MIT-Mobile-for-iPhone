#import <Foundation/Foundation.h>
#import "MITMapView.h"

#warning "Fix implementation for AGSMapView"

@interface CalendarMap : NSObject

- (id)init;
- (id)initWithFrame:(CGRect)frame;

@property (nonatomic, retain) NSArray *events;
@property (nonatomic, retain) MITMapView *view;

@end
