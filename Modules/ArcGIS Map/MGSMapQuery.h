#import <UIKit/UIKit.h>

extern NSString * const MapQueryOptionKeywordKey;
extern NSString * const MapQueryOptionBuildingKey;
extern NSString * const MapQueryOptionFloorKey;
extern NSString * const MapQueryOptionMaximumDistanceMetersKey;

typedef void (^QueryCompleteBlock)(id queryIdentifier, NSString *layerName, NSArray *results, NSError *error);

@interface MGSMapQuery : NSObject
@property (nonatomic,strong) UIImage *marker;
@property (nonatomic,strong) UIColor *color;
@property (nonatomic,strong) NSString *searchType;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,readonly) NSDictionary *queryOptions;

@property (nonatomic,strong) NSString *building;
@property (nonatomic,strong) NSString *floor;

@property (nonatomic,copy) QueryCompleteBlock completionBlock;

- (void)setQueryOption:(NSObject*)option forKey:(NSString*)key;
- (void)removeQueryOptionForKey:(NSString*)key;
- (NSObject*)queryOptionForKey:(NSString*)key;
@end
