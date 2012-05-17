#import "MGSMapViewController.h"
#import "MGSMapView.h"

@interface MGSMapViewController ()

@end

@implementation MGSMapViewController
@synthesize mapView = _mapView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView
{
    UIView *mainView = nil;
    CGRect mainFrame = [[UIScreen mainScreen] applicationFrame];
    CGRect mainBounds = CGRectZero;
    
    if (self.navigationController && (self.navigationController.navigationBarHidden == NO))
    {
        mainFrame.origin.y += CGRectGetHeight(self.navigationController.navigationBar.frame);
        mainFrame.size.height -= CGRectGetHeight(self.navigationController.navigationBar.frame);
    }
    
    {
        mainView = [[UIView alloc] initWithFrame:mainFrame];
        mainView.autoresizesSubviews = YES;
        mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                     UIViewAutoresizingFlexibleWidth);
        mainView.backgroundColor = [UIColor clearColor];
        mainBounds = mainView.bounds;
        self.view = mainView;
    }
    
    {
        MGSMapView *mapView = [[MGSMapView alloc] initWithFrame:mainBounds];
        mapView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                    UIViewAutoresizingFlexibleWidth);
        
        [mainView addSubview:mapView];
        self.mapView = mapView;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
