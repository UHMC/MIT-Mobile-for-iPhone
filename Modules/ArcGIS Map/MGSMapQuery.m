#import "MGSMapQuery.h"

NSString * const MapQueryOptionKeyword = @"edu.mit.mobile.map.query.Keyword";
NSString * const MapQueryOptionBuilding = @"edu.mit.mobile.map.query.Building";
NSString * const MapQueryOptionFloor = @"edu.mit.mobile.map.query.Floor";

@interface MGSMapQuery ()
@property (nonatomic,strong) NSMutableDictionary *options;
@end

@implementation MGSMapQuery
@synthesize marker = _marker;
@synthesize color = _color;
@synthesize searchType = _searchType;
@synthesize options = _options;
@synthesize name = _name;
@synthesize completionBlock = _completionBlock;


@dynamic queryOptions;
@dynamic building;
@dynamic floor;

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.options = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)removeQueryOptionForKey:(NSString*)key
{
    [self.options removeObjectForKey:key];
}

- (void)setQueryOption:(NSObject*)option forKey:(NSString*)key
{
    [self.options setObject:option
                     forKey:key];
}

- (NSObject*)queryOptionForKey:(NSString*)key
{
    return [self.options objectForKey:key];
}


#pragma mark - Dynamic Properties
- (NSDictionary*)queryOptions
{
    return [NSDictionary dictionaryWithDictionary:self.options];
}

- (void)setBuilding:(NSString *)building
{
    if ([building length] == 0)
    {
        [self removeQueryOptionForKey:MapQueryOptionBuilding];
    }
    else
    {
        [self setQueryOption:building
                      forKey:MapQueryOptionBuilding];
    }
}

- (NSString*)building
{
    return (NSString*)[self queryOptionForKey:MapQueryOptionBuilding];
}

- (void)setFloor:(NSString *)floor
{
    if ([floor length] == 0)
    {
        [self removeQueryOptionForKey:MapQueryOptionFloor];
    }
    else
    {
        [self setQueryOption:floor
                      forKey:MapQueryOptionFloor];
    }
}

- (NSString*)floor
{
    return (NSString*)[self queryOptionForKey:MapQueryOptionFloor];
}

@end
