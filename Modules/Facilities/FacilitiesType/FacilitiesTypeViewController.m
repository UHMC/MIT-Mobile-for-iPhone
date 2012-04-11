#import <QuartzCore/QuartzCore.h>

#import "FacilitiesTypeViewController.h"
#import "FacilitiesSummaryViewController.h"
#import "FacilitiesConstants.h"
#import "FacilitiesLocationData.h"
#import "UIKit+MITAdditions.h"
#import "FacilitiesRepairType.h"
#import "CoreDataManager.h"

@interface FacilitiesTypeViewController ()
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) MITLoadingActivityView *loadingView;
@property (nonatomic, strong) NSArray *repairTypes;

@end

@implementation FacilitiesTypeViewController
@synthesize userData = _userData;
@synthesize tableView = _tableView;
@synthesize loadingView = _loadingView;
@synthesize repairTypes = _repairTypes;


- (id)init {
    self = [super init];
    
    if (self) {
        self.title = @"What is it?";
        self.userData = nil;
    }
    
    return self;
}

- (void)dealloc
{
    self.userData = nil;
    self.tableView = nil;
    self.loadingView = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSArray*)repairTypes {
    if (_repairTypes == nil)
    {
        [[FacilitiesLocationData sharedData] allRepairTypes:^(NSSet *objectIDs, NSError *error) {
            [self.loadingView removeFromSuperview];
            self.loadingView = nil;
            self.tableView.hidden = NO;
            
            NSSet *repairTypes = [[CoreDataManager coreDataManager] objectsForObjectIDs:objectIDs];
            self.repairTypes = [repairTypes allObjects];
            [self.tableView reloadData];
        }];
    }
    
    return _repairTypes;
}

#pragma mark - View lifecycle
- (void)loadView {
    CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
    screenFrame.origin = CGPointZero;

    UIView *mainView = [[[UIView alloc] initWithFrame:screenFrame] autorelease];
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor clearColor];

    {
        CGRect tableRect = screenFrame;
        UITableView *tableView = [[[UITableView alloc] initWithFrame: tableRect
                                                               style: UITableViewStyleGrouped] autorelease];
        [tableView applyStandardColors];

        tableView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                           UIViewAutoresizingFlexibleWidth);
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.hidden = YES;
        tableView.scrollEnabled = YES;
        tableView.autoresizesSubviews = YES;

        self.tableView = tableView;
        [mainView addSubview:tableView];
    }

    {
        CGRect loadingFrame = screenFrame;
        MITLoadingActivityView *loadingView = [[[MITLoadingActivityView alloc] initWithFrame:loadingFrame] autorelease];
        loadingView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                             UIViewAutoresizingFlexibleWidth);
        loadingView.backgroundColor = [UIColor clearColor];

        self.loadingView = loadingView;
        [mainView insertSubview:loadingView
                   aboveSubview:self.tableView];
    }

    self.view = mainView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self repairTypes] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier = @"typeCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:reuseIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    FacilitiesRepairType *type = (FacilitiesRepairType *)[[self repairTypes] objectAtIndex:indexPath.row];
    cell.textLabel.text = type.name;

    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self.userData];
    [dict setObject:[[self repairTypes] objectAtIndex:indexPath.row]
             forKey:FacilitiesRequestRepairTypeKey];
    
    FacilitiesSummaryViewController *vc = [[[FacilitiesSummaryViewController alloc] init] autorelease];
    vc.reportData = dict;
    [self.navigationController pushViewController:vc
                                         animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}
@end
