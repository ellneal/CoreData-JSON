//
//  JCImporter.m
//  CoreData+JSON
//
//  Created by Elliot Neal on 02/10/2011.
//  Copyright 2011 emdentec. All rights reserved.
//

#import "JCImporter.h"

#import "JSONKit.h"

#import "JCMappingModel.h"
#import "JCMappingModelCache.h"


#import "NSManagedObject+JSON.h"

@interface JCImporter () {
    
    NSManagedObjectContext *_managedObjectContext;
    NSBundle *_bundle;
}

- (NSArray *)managedObjectsFromJSONObject:(id)jsonObject forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize;

- (NSArray *)fetchObjectsInArray:(NSArray *)jsonObjects forEntity:(NSEntityDescription *)entity withMappedUniqueFieldName:(NSString *)mappedUniqueFieldName;
- (NSArray *)fetchManagedObjectsForEntity:(NSEntityDescription *)entity withUniqueFieldValues:(NSArray *)uniqueFieldValues;


@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSBundle *bundle;

@end


@implementation JCImporter

@synthesize managedObjectContext = _managedObjectContext;
@synthesize bundle = _bundle;


#pragma mark - init/dealloc

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext bundle:(NSBundle *)bundleOrNil {
    
    self = [super init];
    if (self) {
        _managedObjectContext = [managedObjectContext retain];
        _bundle = [bundleOrNil retain];
    }
    return self;
}

- (void)dealloc {
    
    [_managedObjectContext release];
    [_bundle release];
    
    [super dealloc];
}


#pragma mark - Object Importing Public

- (NSArray *)managedObjectsFromJSONData:(NSData *)jsonData forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize {
    
    id jsonObject = [jsonData objectFromJSONData];
    
    return [self managedObjectsFromJSONObject:jsonObject forEntity:entity withBatchSize:batchSize];
}

- (NSArray *)managedObjectsFromJSONString:(NSString *)jsonString forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize {

    id jsonObject = [jsonString objectFromJSONString];
    
    return [self managedObjectsFromJSONObject:jsonObject forEntity:entity withBatchSize:batchSize];
}

- (NSArray *)managedObjectsFromArray:(NSArray *)jsonObjects forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize {
    
    NSUInteger objectCount = [jsonObjects count];
    BOOL useBatching = batchSize > 0;
    
    NSUInteger numberOfBatches = (useBatching ? ceilf(objectCount / batchSize) : 1);
    NSMutableArray *batches = [[NSMutableArray alloc] initWithCapacity:numberOfBatches];
    
    for (int i = 0; i < numberOfBatches; i++) {
        
        NSRange batchRange;
        
        if (i == numberOfBatches)
            batchRange = NSMakeRange(i * batchSize, objectCount % batchSize);
        else
            batchRange = NSMakeRange(i * batchSize, batchSize);
        
        NSArray *batchObjects = [jsonObjects subarrayWithRange:batchRange];
        [batches addObject:batchObjects];
    }
    
    JCMappingModel *mappingModel = [JCMappingModel mappingModelWithEntity:entity bundle:self.bundle];
    NSString *uniqueFieldName = [mappingModel uniqueField];
    NSString *mappedUniqueFieldName = [[mappingModel propertiesMap] objectForKey:uniqueFieldName];
    
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:[jsonObjects count]];
    
    for (NSArray *batchObjects in batches) {
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        NSMutableArray *batchResults = [[NSMutableArray alloc] initWithCapacity:[batchObjects count]];
        
        // we are going to fetch all the managed objects that already exist using the unique field value
        // the array of fetched objects & array of json objects will be ordered by unique field value
        // this way we can iterate through the json objects and check if there is a corresponding fetched object
        // and when there isn't we will generate a new managed object
        NSArray *sortedBatchObjects = [batchObjects sortedArrayUsingComparator:^NSComparisonResult (id obj1, id obj2) {
            
            id unique1 = [obj1 objectForKey:mappedUniqueFieldName];
            id unique2 = [obj2 objectForKey:mappedUniqueFieldName];
            
            return [unique1 compare:unique2];
        }];
        NSArray *fetchedObjects = [self fetchObjectsInArray:batchObjects forEntity:entity withMappedUniqueFieldName:mappedUniqueFieldName];
        
        // this iterations picks out missing objects by stepping through each array
        // 1. get the next json object & managed object
        // 2. check if the unique field values match
        // 3. if they do, increment both indexes
        // 4a. if they don't, create a new managed object and DO NOT increment the fetched object index
        // 4b. get the next json object and check if it matches the last fetched object
        NSUInteger jsonObjectIndex = 0;
        NSUInteger fetchedObjectIndex = 0;
        for (NSDictionary *jsonObject in sortedBatchObjects) {
            
            id jsonUniqueFieldValue = [jsonObject objectForKey:mappedUniqueFieldName];
            
            NSManagedObject *managedObject = [fetchedObjects objectAtIndex:fetchedObjectIndex];
            id managedObjectUniqueFieldValue = [managedObject valueForKey:uniqueFieldName];
            
            if ([jsonUniqueFieldValue isEqual:managedObjectUniqueFieldValue]) {
                //update the object
                fetchedObjectIndex++;
            }
            else {
                //insert the object
            }
            
            //add the managed object to the results
            [batchResults addObject:managedObject];
            
            jsonObjectIndex++;
        }
        
        
        [results addObjectsFromArray:batchResults];
        [batchResults release];
        
        
        if (useBatching) {  // only save the context if batching is enabled
            
            [self.managedObjectContext save:nil];
            [self.managedObjectContext reset];
        }
        
        [pool drain];
    }
    
    [batches release];
    
    return [results autorelease];
}

- (id)managedObjectFromDictionary:(NSDictionary *)jsonObject forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize {
    
    return [NSManagedObject managedObjectWithDictionary:jsonObject entity:entity managedObjectContext:self.managedObjectContext];
}


#pragma mark - Object Importing Private

- (NSArray *)managedObjectsFromJSONObject:(id)jsonObject forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize {
    
    if ([jsonObject isKindOfClass:[NSDictionary class]])
        return [NSArray arrayWithObject:[self managedObjectFromDictionary:jsonObject forEntity:entity withBatchSize:batchSize]];
    
    return [self managedObjectsFromArray:jsonObject forEntity:entity withBatchSize:batchSize];
}


#pragma mark - Object Fetching

- (NSArray *)fetchObjectsInArray:(NSArray *)jsonObjects forEntity:(NSEntityDescription *)entity withMappedUniqueFieldName:(NSString *)mappedUniqueFieldName {
    
    NSMutableArray *uniqueFieldValues = [[NSMutableArray alloc] initWithCapacity:[jsonObjects count]];
    
    for (NSDictionary *jsonObject in jsonObjects)
        [uniqueFieldValues addObject:[jsonObject objectForKey:mappedUniqueFieldName]];
    
    NSArray *managedObjects = [self fetchManagedObjectsForEntity:entity withUniqueFieldValues:uniqueFieldValues];
    [uniqueFieldValues release];
    
    return managedObjects;
}

- (NSArray *)fetchManagedObjectsForEntity:(NSEntityDescription *)entity withUniqueFieldValues:(NSArray *)uniqueFieldValues {
    
    JCMappingModel *mappingModel = [JCMappingModel mappingModelWithEntity:entity bundle:self.bundle];
    NSString *uniqueFieldName = [mappingModel uniqueField];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K IN %@)", uniqueFieldName, uniqueFieldValues];
    [fetchRequest setPredicate:predicate];
    
    NSMutableArray *results = [[self.managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    [fetchRequest release];
    
    [results sortUsingComparator:^NSComparisonResult (id obj1, id obj2) {
        
        id unique1 = [obj1 valueForKey:uniqueFieldName];
        id unique2 = [obj2 valueForKey:uniqueFieldName];
        
        return [unique1 compare:unique2];
    }];
    
    return [results autorelease];
}

@end
