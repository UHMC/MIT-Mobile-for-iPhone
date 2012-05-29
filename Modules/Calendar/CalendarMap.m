#import "CalendarMap.h"
#import "MITCalendarEvent.h"
#import "CalendarEventMapAnnotation.h"

@implementation CalendarMap
@synthesize events = _events;
@synthesize view = _view;

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super init];

    if (self)
    {
        self.events = nil;
        self.view = [[[MITMapView alloc] initWithFrame:frame] autorelease];
    }

    return self;
}

- (void)dealloc
{
    self.events = nil;
    self.view = nil;

    [super dealloc];
}

/*
 * while setting events
 * create map annotations for all events that we can map
 * and get min/max lat/lon for map region
 */
- (void)setEvents:(NSArray *)events
{
    [self.view removeAllAnnotations:YES];
    
    [_events release];
	_events = [events retain];
    
    if ([_events count]) {
        
        double minLat = 90;
        double maxLat = -90;
        double minLon = 180;
        double maxLon = -180;
        
        for (MITCalendarEvent *event in [events reverseObjectEnumerator]) {
            if ([event hasCoords]) {
                CalendarEventMapAnnotation *annotation = [[[CalendarEventMapAnnotation alloc] initWithEvent:event] autorelease];
                [self.view addAnnotation:annotation];
				
                double eventLat = [event.latitude doubleValue];
                double eventLon = [event.longitude doubleValue];
                if (eventLat < minLat) {
                    minLat = eventLat;
                }
                if (eventLat > maxLat) {
                    maxLat = eventLat;
                }
                if(eventLon < minLon) {
                    minLon = eventLon;
                }
                if (eventLon > maxLon) {
                    maxLon = eventLon;
                }
            }
        }
        
        if (maxLon == -180)
            return;
        
        CLLocationCoordinate2D center;
        center.latitude = minLat + (maxLat - minLat) / 2;
        center.longitude = minLon + (maxLon - minLon) / 2;
        
        double latDelta = maxLat - minLat;
        double lonDelta = maxLon - minLon; 
        
        MKCoordinateSpan span = MKCoordinateSpanMake(latDelta + latDelta / 4, lonDelta + lonDelta / 4);
        
        [self.view setRegion:MKCoordinateRegionMake(center, span)];

    } else {
        [self.view setRegion:MKCoordinateRegionMake(DEFAULT_MAP_CENTER, DEFAULT_MAP_SPAN)];
    }
    
}

@end
