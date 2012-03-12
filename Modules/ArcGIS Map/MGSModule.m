#import "MGSModule.h"
#import "MITModule+Protected.h"
#import "MGSMapViewController.h"

@implementation MGSModule
- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = LibrariesTag;
        self.shortName = @"ArcGIS";
        self.longName = @"ArcGIS Map";
        self.iconName = @"map";
    }
    return self;
}

- (void) dealloc {
    [super dealloc];
}

- (void)loadModuleHomeController
{
    self.moduleHomeController = [[[MGSMapViewController alloc] initWithNibName:nil bundle:nil] autorelease];
}
@end
