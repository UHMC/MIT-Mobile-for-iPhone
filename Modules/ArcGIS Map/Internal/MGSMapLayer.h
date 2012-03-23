#import <Foundation/Foundation.h>

@interface MGSMapLayer : NSObject
@property (nonatomic,getter=isHidden) BOOL hidden;
@property (nonatomic,assign) id layerDelegate;
@property (nonatomic,readonly,strong) NSString *name;

- (id)initWithName:(NSString*)name;
@end
