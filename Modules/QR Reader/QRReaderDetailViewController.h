#import <UIKit/UIKit.h>
#import "ShareDetailViewController.h"


@class QRReaderResult;
@interface QRReaderDetailViewController : ShareDetailViewController

@property (readonly,retain) QRReaderResult *scanResult;
@property (readonly,assign) IBOutlet UIImageView *qrImageView;
@property (readonly,assign) IBOutlet UIImageView *backgroundImageView;
@property (readonly,assign) IBOutlet UILabel *textTitleLabel;
@property (readonly,assign) IBOutlet UITextView *textView;
@property (readonly,assign) IBOutlet UILabel *dateLabel;
@property (readonly,assign) IBOutlet UIButton *actionButton;
@property (readonly,assign) IBOutlet UIButton *shareButton;

+ (QRReaderDetailViewController*)detailViewControllerForResult:(QRReaderResult*)result;
- (IBAction)pressedShareButton:(id)sender;
- (IBAction)pressedActionButton:(id)sender;

@end
