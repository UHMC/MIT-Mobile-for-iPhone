#import "FacilitiesLocationData.h"

#import "CoreDataManager.h"
#import "FacilitiesCategory.h"
#import "FacilitiesLocation.h"
#import "FacilitiesRoom.h"
#import "FacilitiesPropertyOwner.h"
#import "FacilitiesContent.h"
#import "MITMobileServerConfiguration.h"
#import "ConnectionDetector.h"
#import "FacilitiesRepairType.h"
#import "ModuleVersions.h"
#import "MobileRequestOperation.h"
#import "Foundation+MITAdditions.h"

NSString* const FacilitiesDidLoadDataNotification = @"MITFacilitiesDidLoadData";

NSString * const FacilitiesCategoriesKey = @"categorylist";
NSString * const FacilitiesLocationsKey = @"location";
NSString * const FacilitiesRoomsKey = @"room";
NSString * const FacilitiesRepairTypesKey = @"problemtype";

static NSString *FacilitiesFetchDatesKey = @"FacilitiesDataFetchDates";

static FacilitiesLocationData *_sharedData = nil;

@interface FacilitiesLocationData ()
@property (nonatomic,retain) NSOperationQueue* requestQueue;

- (BOOL)shouldUpdateDataWithRequest:(MobileRequestOperation*)request;

- (void)loadRequestData:(id)data requestCommand:(NSString*)command;
- (void)loadCategoriesWithArray:(id)categories;
- (void)loadLocationsWithArray:(NSArray*)locations;
- (void)loadContentsForLocation:(FacilitiesLocation*)location withData:(NSArray*)contents;
- (void)loadRoomsWithData:(NSDictionary*)roomData;
- (void)loadRepairTypesWithArray:(NSArray*)typeData;

- (FacilitiesCategory*)categoryForId:(NSString*)categoryId;
- (FacilitiesLocation*)locationForId:(NSString*)locationId;
- (FacilitiesLocation*)locationWithNumber:(NSString*)bldgNumber;

- (BOOL)hasActiveRequest:(MobileRequestOperation*)request;
@end

@implementation FacilitiesLocationData
@synthesize requestQueue = _requestQueue;

- (id)init {
    self = [super init]; 
    
    if (self) {
        self.requestQueue = [[[NSOperationQueue alloc] init] autorelease];
        self.requestQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

- (void)dealloc {
    self.requestQueue = nil;
    [super dealloc];
}

#pragma mark - Private Methods
- (NSString*)stringForRequestParameters:(NSDictionary*)params {
    NSMutableString *string = [NSMutableString string];
    
    [string appendFormat:@"%@?",[MITMobileWebGetCurrentServerURL() absoluteString]];
    for (NSString *key in params) {
        [string appendFormat:@"%@=%@&",key, [params objectForKey:key]];
    }
    
    [string deleteCharactersInRange:NSMakeRange([string length]-1, 1)];
    return [NSString stringWithString:string];
}

- (BOOL)shouldUpdateDataWithRequest:(MobileRequestOperation*)request {
    NSDictionary *parameters = request.parameters;
    NSString *command = request.command;
    
    if ([ConnectionDetector isConnected] == NO) {
        return NO;
    }
    
    NSDate *lastCheckDate = nil;
    if ([command isEqualToString:FacilitiesRoomsKey] && [parameters objectForKey:@"building"]) {
        FacilitiesLocation *location = [self locationWithNumber:[parameters objectForKey:@"building"]];
        [[[CoreDataManager coreDataManager] managedObjectContext] refreshObject:location mergeChanges:NO];
        lastCheckDate = location.roomsUpdated;
    } else {
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:FacilitiesFetchDatesKey];
        if (dict == nil) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionary]
                                                      forKey:FacilitiesFetchDatesKey];
            return YES;
        } else {
            lastCheckDate = [dict objectForKey:command];
            
            if ([lastCheckDate isKindOfClass:[NSDate class]] == NO) {
                lastCheckDate = nil;
            }
        }
    }

    NSDate *updateDate = nil;
    NSDictionary *serverDates = nil;

    if ([command isEqualToString:FacilitiesCategoriesKey]) {
        serverDates = [[ModuleVersions sharedVersions] lastUpdateDatesForModule:@"map"];
        updateDate = [serverDates objectForKey:@"category_list"];
    } else if ([command isEqualToString:FacilitiesLocationsKey]) {
        serverDates = [[ModuleVersions sharedVersions] lastUpdateDatesForModule:@"map"];
        updateDate = [serverDates objectForKey:@"location"];
    } else if ([command isEqualToString:FacilitiesRoomsKey]) {
        serverDates = [[ModuleVersions sharedVersions] lastUpdateDatesForModule:@"facilities"];
        updateDate = [serverDates objectForKey:@"room"];
    } else if ([command isEqualToString:FacilitiesRepairTypesKey]) {
        serverDates = [[ModuleVersions sharedVersions] lastUpdateDatesForModule:@"facilities"];
        updateDate = [serverDates objectForKey:@"problem_type"];
    } else {
        updateDate = [NSDate distantFuture];
    }

    if (lastCheckDate == nil) {
        return YES;
    } else if ([lastCheckDate timeIntervalSinceDate:updateDate] < 0) {
        return YES;
    }

    return NO;
}


#pragma mark - Internal ID accessors
- (FacilitiesCategory*)categoryForId:(NSString*)categoryId {
    NSPredicate *predicate = nil;
    if (categoryId) {
        predicate = [NSPredicate predicateWithFormat:@"uid == %@",categoryId];
    } else {
        return nil;
    }
    
    NSArray *fetchedData = [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesCategory"
                                                             matchingPredicate:predicate];
    if (fetchedData && ([fetchedData count] > 0)) {
        return [fetchedData objectAtIndex:0];
    } else {
        return nil;
    }
}

- (FacilitiesLocation*)locationForId:(NSString*)locationId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid == %@",locationId];
    NSArray *fetchedData = [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesLocation"
                                                             matchingPredicate:predicate];
    if (fetchedData && ([fetchedData count] > 0)) {
        return [fetchedData objectAtIndex:0];
    } else {
        return nil;
    }
}

- (FacilitiesLocation*)locationWithNumber:(NSString*)bldgNumber {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"number == %@",bldgNumber];
    NSArray *fetchedData = [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesLocation"
                                                             matchingPredicate:predicate];
    if (fetchedData && ([fetchedData count] > 0)) {
        return [fetchedData objectAtIndex:0];
    } else {
        return nil;
    }
}


#pragma mark - JSON Loading/Updating methods
- (void)loadRequestData:(id)data requestCommand:(NSString*)command
{
    if ([command isEqualToString:FacilitiesCategoriesKey])
    {
        [self loadCategoriesWithArray:data];
    }
    else if ([command isEqualToString:FacilitiesLocationsKey])
    {
        [self loadLocationsWithArray:data];
    }
    else if ([command isEqualToString:FacilitiesRoomsKey])
    {
        [self loadRoomsWithData:data];
    }
    else if ([command isEqualToString:FacilitiesRepairTypesKey])
    {
        [self loadRepairTypesWithArray:data];
    }
    else
    {
        ELog(@"Error: Unknown command type '%@'", command);
    }
}

- (void)loadCategoriesWithArray:(id)categories {
    CoreDataManager *cdm = [CoreDataManager coreDataManager];
    [cdm deleteObjectsForEntity:@"FacilitiesCategory"];

    if ([categories isKindOfClass:[NSArray class]]) {
        NSArray *catArray = (NSArray*)categories;
        for (NSDictionary *catData in catArray) {
            FacilitiesCategory *category = [self categoryForId:[catData objectForKey:@"id"]];
                                            
            if (category == nil) {
                category = [cdm insertNewObjectForEntityForName:@"FacilitiesCategory"];
            }
            
            category.uid = [catData objectForKey:@"id"];
            category.name = [catData objectForKey:@"name"];
            
            NSArray *locations = [cdm objectsForEntity:@"FacilitiesLocation"
                                     matchingPredicate:[NSPredicate predicateWithFormat:@"ANY categories.uid == %@", category.uid]];
            category.locations = [NSSet setWithArray:locations];
        }
    } else {
        NSDictionary *catDict = (NSDictionary*)categories;
        for (NSString *categoryId in catDict) {
            FacilitiesCategory *category = [self categoryForId:categoryId];
            
            if (category == nil) {
                category = [cdm insertNewObjectForEntityForName:@"FacilitiesCategory"];
            }
            
            NSDictionary *categoryData = [catDict valueForKey:categoryId];
            category.uid = categoryId;
            category.name = [categoryData valueForKey:@"name"];
            category.locationIds = [NSSet setWithArray:[categoryData valueForKey:@"locations"]];
            
            for (NSString *locationId in category.locationIds) {
                FacilitiesLocation *location = [self locationForId:locationId];
                if (location) {
                    [location addCategoriesObject:category];
                }
            }
        }
        
        NSArray *allLocations = [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesLocation"
                                                                  matchingPredicate:[NSPredicate predicateWithValue:YES]];
        for (FacilitiesLocation *location in allLocations) {
            for (FacilitiesCategory *category in [location.categories allObjects]) {
                if ([category.locationIds containsObject:location.uid] == NO) {
                    [category removeLocationsObject:location];
                }
            }
        }
    }
    
    [cdm saveData];
}

- (void)loadLocationsWithArray:(NSArray*)locations {
    CoreDataManager *cdm = [CoreDataManager coreDataManager];
    
    NSMutableSet *allObjects = [NSSet setWithArray:[cdm objectsForEntity:@"FacilitiesLocation"
                                                       matchingPredicate:[NSPredicate predicateWithValue:YES]]];
    NSMutableSet *modifiedObjects = [NSMutableSet set];
    
    for (NSDictionary *loc in locations) {
        FacilitiesLocation *location = [[allObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
            if ([[obj valueForKey:@"uid"] isEqualToString:[loc objectForKey:@"id"]]) {
                *stop = YES;
                return YES;
            }
            
            return NO;
        }] anyObject];
        
        if (location == nil) {
            location = [cdm insertNewObjectForEntityForName:@"FacilitiesLocation"];
            location.uid = [loc objectForKey:@"id"];
        }
        
        location.name = [loc objectForKey:@"name"];
        location.number = [loc objectForKey:@"bldgnum"];
        
        location.longitude = [NSNumber numberWithDouble:[[loc objectForKey:@"long_wgs84"] doubleValue]];
        location.latitude = [NSNumber numberWithDouble:[[loc objectForKey:@"lat_wgs84"] doubleValue]];
        
        if ([[loc objectForKey:@"hidden_bldg_services"] boolValue] == YES) {
            location.isHiddenInBldgServices = [NSNumber numberWithBool:YES];
        }
        
        if ([[loc objectForKey:@"leased_bldg_services"] boolValue] == YES) {
            NSString *name = [loc objectForKey:@"contact-name_bldg_services"];
            if (!name) {
                WLog(@"Leased location \"%@\" missing contact name.", location.uid);
            } else {
                FacilitiesPropertyOwner *propertyOwner = [cdm getObjectForEntity:@"FacilitiesPropertyOwner" attribute:@"name" value:name];
                if (!propertyOwner) {
                    propertyOwner = [cdm insertNewObjectForEntityForName:@"FacilitiesPropertyOwner"];
                    propertyOwner.name = name;
                    propertyOwner.phone = [loc objectForKey:@"contact-phone_bldg_services"];
                    propertyOwner.email = [loc objectForKey:@"contact-email_bldg_services"];
                }
                location.propertyOwner = propertyOwner;
                location.isLeased = [NSNumber numberWithBool:YES];
            }
        }
        
        [self loadContentsForLocation:location withData:[loc objectForKey:@"contents"]];
        [modifiedObjects addObject:location];
    }
    
    NSMutableSet *deletedObjects = [NSMutableSet setWithSet:allObjects];
    [deletedObjects minusSet:modifiedObjects];
    [cdm deleteObjects:[deletedObjects allObjects]];
    
    NSArray *allCategories = [cdm objectsForEntity:@"FacilitiesCategory" matchingPredicate:[NSPredicate predicateWithValue:YES]];
    
    NSPredicate *template = [NSPredicate predicateWithFormat:@"uid in $uids"];
    
    [allCategories enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        FacilitiesCategory *category = obj;
        NSSet *locationIds = category.locationIds;
        if (locationIds) {
            NSPredicate *predicate = [template predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:locationIds forKey:@"uids"]];
            category.locations = [modifiedObjects filteredSetUsingPredicate:predicate];
        }
    }];
    
    [cdm saveData];
}

- (void)loadContentsForLocation:(FacilitiesLocation*)location withData:(NSArray*)contents {
    if ((contents == nil) || [[NSNull null] isEqual:contents]) {
        return;
    }
    
    NSMutableSet *allContents = [NSMutableSet setWithSet:location.contents];
    NSMutableSet *modifiedContents = [NSMutableSet set];
    
    CoreDataManager *cdm = [CoreDataManager coreDataManager];
    
    for (NSDictionary *contentData in contents) {
        NSString *name = [contentData objectForKey:@"name"];
        FacilitiesContent *content = [[allContents objectsPassingTest:^BOOL(id obj, BOOL *stop) {
            if ([[obj valueForKey:@"name"] isEqualToString:name]) {
                *stop = YES;
                return YES;
            }
            
            return NO;
        }] anyObject];
        
        if (content == nil) {
            content = [cdm insertNewObjectForEntityForName:@"FacilitiesContent"];
            content.location = location;
            content.name = name;
        }
        
        if ([contentData objectForKey:@"url"]) {
            content.url = [NSURL URLWithString:[contentData objectForKey:@"url"]];
        }
        
        if ([contentData objectForKey:@"altname"]) {
            content.altname = [contentData objectForKey:@"altname"];
        }
        
        [modifiedContents addObject:content];
        
        // bskinner - 07/06/2011
        // Commented out, categories are not being used
        //  at the moment.
        /*
        if ([contentData objectForKey:@"category"]) {
            NSArray *contentCategories = [contentData objectForKey:@"category"];
            for (NSString *catName in contentCategories) {
                FacilitiesCategory *category = [self categoryForId:catName];
                if (category) {
                    [content addCategoriesObject:category];
                }
            }
        }
        */
    }
    
    [allContents minusSet:modifiedContents];
    [location removeContents:allContents];
    
    if ([allContents count] > 0) {
        [cdm deleteObjects:[allContents allObjects]];
    }
}


- (void)loadRoomsWithData:(NSDictionary*)roomData {
    CoreDataManager *cdm = [CoreDataManager coreDataManager];
    
    for (NSString *building in [roomData allKeys]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"building == %@",building];
        NSArray *bldgRooms = [cdm objectsForEntity:@"FacilitiesRoom"
                                 matchingPredicate:predicate];
        [cdm deleteObjects:bldgRooms];
        
        NSDictionary *floorData = [roomData objectForKey:building];
        
        if ([floorData isEqual:[NSNull null]]) {
            continue;
        }
        
        for (NSString *floor in [floorData allKeys]) {
            NSArray *rooms = [floorData objectForKey:floor];
            
            for (NSString *room in rooms) {
                FacilitiesRoom *moRoom = [cdm insertNewObjectForEntityForName:@"FacilitiesRoom"];
                moRoom.number = room;
                moRoom.floor = floor;
                moRoom.building = building;
            }
        }

        FacilitiesLocation *location = [self locationWithNumber:building];
        location.roomsUpdated = [NSDate date];
    }
    
    [cdm saveData];
}

- (void)loadRepairTypesWithArray:(NSArray*)typeData {
    CoreDataManager *cdm = [CoreDataManager coreDataManager];
    [cdm deleteObjectsForEntity:@"FacilitiesRepairType"];
    
    NSInteger index = 0;
    for (NSString *type in typeData) {
        FacilitiesRepairType *repairType = [cdm insertNewObjectForEntityForName:@"FacilitiesRepairType"];
        repairType.name = type;
        repairType.order = [NSNumber numberWithInteger:index];
        ++index;
    }
    
    [cdm saveData];
}

#pragma mark - MITMobileWebAPI request management
- (BOOL)hasActiveRequest:(MobileRequestOperation*)request {
    return [[self.requestQueue operations] containsObject:request];
}


#pragma mark - Asynchronous request methods
- (void)allCategories:(LocationResultBlock)resultBlock
{
    [self performRequestForType:FacilitiesCategoriesKey
                  forEntityName:@"FacilitiesCategory"
              matchingPredicate:[NSPredicate predicateWithValue:YES]
                      completed:resultBlock];
}

- (void)allLocations:(LocationResultBlock)resultBlock
{
    [self performRequestForType:FacilitiesLocationsKey
                  forEntityName:@"FacilitiesLocation"
              matchingPredicate:[NSPredicate predicateWithValue:YES]
                      completed:resultBlock];
}

- (void)locationsInCategory:(NSString*)categoryId
           requestCompleted:(LocationResultBlock)resultBlock
{
    [self performRequestForType:FacilitiesLocationsKey
                  forEntityName:@"FacilitiesLocation"
              matchingPredicate:[NSPredicate predicateWithFormat:@"(ANY categories.uid == %@)", categoryId]
                      completed:resultBlock];
}

- (void)roomsForBuilding:(NSString*)bldgnum
        requestCompleted:(LocationResultBlock)resultBlock
{
    [self performRequestForType:FacilitiesRoomsKey
                  forEntityName:@"FacilitiesRoom"
              matchingPredicate:[NSPredicate predicateWithFormat:@"building LIKE[cd] %@",bldgnum]
                      completed:resultBlock];
}

- (void)hiddenBuildings:(LocationResultBlock)resultBlock
{
    [self performRequestForType:FacilitiesLocationsKey
                  forEntityName:@"FacilitiesLocation"
              matchingPredicate:[NSPredicate predicateWithFormat:@"isHiddenInBldgServices == YES"]
                      completed:resultBlock];
}

- (void)leasedBuildings:(LocationResultBlock)resultBlock
{
    [self performRequestForType:FacilitiesLocationsKey
                  forEntityName:@"FacilitiesLocation"
              matchingPredicate:[NSPredicate predicateWithFormat:@"isLeased == YES"]
                      completed:resultBlock];
}

- (void)allRepairTypes:(LocationResultBlock)resultBlock
{
    [self performRequestForType:FacilitiesRepairTypesKey
                  forEntityName:@"FacilitiesRepairType"
              matchingPredicate:[NSPredicate predicateWithValue:YES]
                      completed:resultBlock];
}


#pragma mark - Notification Block Management
- (void)performRequestForType:(NSString*)dataKey
                forEntityName:(NSString*)entity
            matchingPredicate:(NSPredicate*)predicate
                    completed:(LocationResultBlock)resultBlock
{
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithModule:@"facilities"
                                                                              command:dataKey
                                                                           parameters:nil] autorelease];
    LocationResultBlock localResultBlock = [[resultBlock copy] autorelease];
    
    dispatch_block_t execBlock = ^{
        if (localResultBlock)
        {
            NSSet *objectIDs = [[CoreDataManager coreDataManager] objectIDsForEntity:entity
                                                                   matchingPredicate:predicate];
            localResultBlock(objectIDs, nil);
        }
    };
    
    if (([self hasActiveRequest:request] == NO) && [self shouldUpdateDataWithRequest:request])
    {
        request.requestCompleteBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error)
        {
            if (error)
            {
                ELog(@"Request failed with error: %@",[error localizedDescription]);
                [self performBlockOnMainThread:execBlock
                                 waitUntilDone:NO];
            }
            else
            {
                NSBlockOperation *opBlock = [NSBlockOperation blockOperationWithBlock: ^{
                    [self loadRequestData:jsonResult
                           requestCommand:dataKey];
             
                    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:FacilitiesFetchDatesKey]];
                    [dict setObject:[NSDate date]
                             forKey:dataKey];
                    [[NSUserDefaults standardUserDefaults] setObject:dict
                                                              forKey:FacilitiesFetchDatesKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    [self performBlockOnMainThread:execBlock
                                     waitUntilDone:NO];
                }];
                
                [self.requestQueue addOperation:opBlock];
            }
        };
        
        [self.requestQueue addOperation:request];
    }
    else if ([self hasActiveRequest:request] == NO)
    {
        [self.requestQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
            [self performBlockOnMainThread:execBlock
                             waitUntilDone:NO];
        }]];
    } 
}


#pragma mark - Singleton Implementation
+ (void)initialize {
    if (_sharedData == nil) {
        _sharedData = [[super allocWithZone:NULL] init];
    }
}

+ (FacilitiesLocationData*)sharedData {
    return _sharedData;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedData] retain];
}

- (id)copyWithZone:(NSZone*)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (oneway void)release {
    return;
}

- (id)autorelease {
    return self;
}

@end
