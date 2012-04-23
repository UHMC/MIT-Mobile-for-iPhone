#import <Foundation/Foundation.h>

@protocol MCDUpdateProtocol <NSObject>
- (BOOL)isUpdating;
- (BOOL)entityNeedsUpdate;
- (void)performEntityUpdate:(dispatch_block_t)completedBlock;
@end
