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

- (NSArray *)importObjectsFromJSONObject:(id)jsonObject forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize;

- (NSArray *)fetchManagedObjectsForEntity:(NSEntityDescription *)entity withUniqueFieldValues:(NSArray *)uniqueFieldValues;


@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSBundle *bundle;

@end


@implementation JCImporter

@synthesize managedObjectContext = _managedObjectContext;
@synthesize bundle = _bundle;


#pragma mark - init/dealloc

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext bundle:(NSBundle *)bundle {
    
    self = [super init];
    if (self) {
        _managedObjectContext = [managedObjectContext retain];
        _bundle = [bundle retain];
    }
    return self;
}

- (void)dealloc {
    
    [_managedObjectContext release];
    [_bundle release];
    
    [super dealloc];
}


#pragma mark - Object Importing

- (NSArray *)importObjectsFromJSONData:(NSData *)jsonData forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize {
    
    id jsonObject = [jsonData objectFromJSONData];
    
    return [self importObjectsFromJSONObject:jsonObject forEntity:entity withBatchSize:batchSize];
}

- (NSArray *)importObjectsFromJSONString:(NSString *)jsonString forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize {

    id jsonObject = [jsonString objectFromJSONString];
    
    return [self importObjectsFromJSONObject:jsonObject forEntity:entity withBatchSize:batchSize];
}

- (NSArray *)importObjectsFromJSONObject:(id)jsonObject forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize {
    
    if ([jsonObject isKindOfClass:[NSDictionary class]])
        return [NSArray arrayWithObject:[self importObjectFromDictionary:jsonObject forEntity:entity withBatchSize:batchSize]];
    
    return [self importObjectsFromArray:jsonObject forEntity:entity withBatchSize:batchSize];
}

- (NSArray *)importObjectsFromArray:(NSArray *)jsonObjects forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize {
    
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:[jsonObjects count]];
    BOOL useBatching = batchSize > 0;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    for (int i = 0; i < [jsonObjects count]; i++) {
        
        NSDictionary *jsonObject = [jsonObjects objectAtIndex:i];
        [results addObject:[NSManagedObject managedObjectWithDictionary:jsonObject entity:entity managedObjectContext:self.managedObjectContext]];
        
        if (useBatching && i % batchSize == 0) {
            NSLog(@"Generated %d objects", i);
            [self.managedObjectContext save:nil];
            [self.managedObjectContext reset];
            
            [pool drain];
            pool = [[NSAutoreleasePool alloc] init];
        }
    }
    
    [pool drain];
    
    return [results autorelease];
    
//    JCMappingModel *mappingModel = [JCMappingModel mappingModelWithEntity:entity bundle:self.bundle];
//    NSString *uniqueFieldName = [mappingModel uniqueField];
//    NSString *mappedUniqueFieldName = [[mappingModel propertiesMap] objectForKey:uniqueFieldName];
//    
//    NSMutableArray *uniqueFieldValues = [[NSMutableArray alloc] initWithCapacity:[jsonObjects count]];
//    
//    for (NSDictionary *jsonObject in jsonObjects)
//        [uniqueFieldValues addObject:[jsonObject objectForKey:mappedUniqueFieldName]];
}

- (id)importObjectFromDictionary:(NSDictionary *)jsonObject forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize {
    
    return [NSManagedObject managedObjectWithDictionary:jsonObject entity:entity managedObjectContext:self.managedObjectContext];
}


#pragma mark - Object Fetching

- (NSArray *)fetchManagedObjectsForEntity:(NSEntityDescription *)entity withUniqueFieldValues:(NSArray *)uniqueFieldValues {
    
    JCMappingModel *mappingModel = [JCMappingModel mappingModelWithEntity:entity bundle:self.bundle];
    NSString *uniqueFieldName = [mappingModel uniqueField];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K IN %@)", uniqueFieldName, uniqueFieldValues];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:uniqueFieldName ascending:YES];
    
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    [fetchRequest release];
    
    return results;
}

@end
