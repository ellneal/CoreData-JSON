//
//  JCImporter.m
//  CoreData+JSON
//
//	Copyright (c) 2011, emdentec (Elliot Neal)
//	All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without
//	modification, are permitted provided that the following conditions are met:
//		* Redistributions of source code must retain the above copyright
//		  notice, this list of conditions and the following disclaimer.
//		* Redistributions in binary form must reproduce the above copyright
//		  notice, this list of conditions and the following disclaimer in the
//		  documentation and/or other materials provided with the distribution.
//		* Neither the name of emdentec nor the
//		  names of its contributors may be used to endorse or promote products
//		  derived from this software without specific prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY
//	DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "JCImporter.h"

#import "JSONKit.h"
#import "ConvenienceCategories.h"
#import "JCMappingModel.h"
#import "JCMappingModelCache.h"
#import "JCProxyObject.h"
#import "JCProxyObjectCache.h"

#import "NSManagedObject+JSON.h"

#import "CoreData+JSON.h"

@interface JCImporter () {
    
    NSManagedObjectContext *_managedObjectContext;
    NSBundle *_bundle;
}

- (NSArray *)managedObjectsFromArray:(NSArray *)jsonObjects forEntity:(NSEntityDescription *)entity superUniqueFieldValue:(id)superUniqueFieldValue;

- (NSArray *)managedObjectsFromJSONObject:(id)jsonObject forEntity:(NSEntityDescription *)entity;

- (NSArray *)managedObjectIDsFromCache:(JCProxyObjectCache *)objectCache;


@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSBundle *bundle;

@end


@implementation JCImporter

@synthesize managedObjectContext = _managedObjectContext;
@synthesize importBatchSize = _importBatchSize;
@synthesize saveBatchSize = _saveBatchSize;
@synthesize resetManagedObjectContext = _resetManagedObjectContext;

@synthesize bundle = _bundle;


#pragma mark - init/dealloc

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext bundle:(NSBundle *)bundleOrNil {
    
    self = [super init];
    if (self) {
        _managedObjectContext = [managedObjectContext retain];
        _importBatchSize = 0;
        _saveBatchSize = 0;
        _resetManagedObjectContext = NO;
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

- (NSArray *)managedObjectsFromJSONData:(NSData *)jsonData forEntity:(NSEntityDescription *)entity {
    
    id jsonObject = [jsonData objectFromJSONData];
    
    return [self managedObjectsFromJSONObject:jsonObject forEntity:entity];
}

- (NSArray *)managedObjectsFromJSONString:(NSString *)jsonString forEntity:(NSEntityDescription *)entity {

    id jsonObject = [jsonString objectFromJSONString];
    
    return [self managedObjectsFromJSONObject:jsonObject forEntity:entity];
}

- (NSArray *)managedObjectsFromArray:(NSArray *)jsonObjects forEntity:(NSEntityDescription *)entity {
    
    return [self managedObjectsFromArray:jsonObjects forEntity:entity superUniqueFieldValue:nil];
}

- (NSManagedObject *)managedObjectFromDictionary:(NSDictionary *)jsonObject forEntity:(NSEntityDescription *)entity {
    
    NSArray *results = [self managedObjectsFromArray:[NSArray arrayWithObject:jsonObject] forEntity:entity];
    if ([results count] > 0)
        return [results objectAtIndex:0];
    
    return nil;
}


#pragma mark - Object Importing Private

- (NSArray *)managedObjectsFromArray:(NSArray *)jsonObjects forEntity:(NSEntityDescription *)entity superUniqueFieldValue:(id)superUniqueFieldValue {
    
    JCProxyObjectCache *cache = [[JCProxyObjectCache alloc] initWithEntity:entity managedObjectContext:self.managedObjectContext bundle:self.bundle];
    [cache addProxyObjectsFromJSONObjects:jsonObjects superUniqueFieldValue:superUniqueFieldValue];
    
    NSArray *resultIDs = [self managedObjectIDsFromCache:cache];
    [cache release];
    
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:[resultIDs count]];
    for (NSManagedObjectID *managedObjectID in resultIDs)
        [results addObject:[self.managedObjectContext objectWithID:managedObjectID]];
    
    return [results autorelease];
    
}

- (NSArray *)managedObjectsFromJSONObject:(id)jsonObject forEntity:(NSEntityDescription *)entity {
    
    NSArray *jsonObjects = nil;
    
    if ([jsonObject isKindOfClass:[NSDictionary class]])
        jsonObjects = [NSArray arrayWithObject:jsonObject];
    else
        jsonObjects = jsonObject;
    
    return [self managedObjectsFromArray:jsonObjects forEntity:entity];
}

- (NSArray *)managedObjectIDsFromCache:(JCProxyObjectCache *)objectCache {
    
    NSMutableArray *managedObjects = [[NSMutableArray alloc] initWithCapacity:[objectCache count]];
    
    NSUInteger importBatchSize = self.importBatchSize;
    NSUInteger saveBatchSize = self.saveBatchSize;
    NSUInteger objectCount = [objectCache count];
    BOOL useImportBatching = importBatchSize > 0;
    BOOL useSaveBatching = (useImportBatching && (importBatchSize != saveBatchSize));
    
    if (objectCount == 0) {
        [managedObjects release];
        return nil;
    }
    
    if (!useImportBatching)
        importBatchSize = [objectCache count];
    
    NSUInteger numberOfBatches = (useImportBatching && objectCount > importBatchSize ? ceilf(objectCount / importBatchSize) : 1);
    NSMutableArray *batches = [[NSMutableArray alloc] initWithCapacity:numberOfBatches];
    
    for (int i = 0; i < numberOfBatches; i++) {
        
        NSRange batchRange;
        
        if ((i == (numberOfBatches - 1)) && (objectCount % importBatchSize != 0))
            batchRange = NSMakeRange(i * importBatchSize, objectCount % importBatchSize);
        else
            batchRange = NSMakeRange(i * importBatchSize, importBatchSize);
        
        JCProxyObjectCache *batchCache = [objectCache subcacheWithRange:batchRange];
        [batches addObject:batchCache];
    }

    //start
    for (int i = 0; i < [batches count]; i++) {
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        JCProxyObjectCache *batchCache = [batches objectAtIndex:i];
        
//        if (JC_LOGGING_ENABLED)
//            NSLog(@"Starting batch %d of %d for entity %@", i, numberOfBatches, [[batchCache entity] name]);
        
        //perform the fetch
        [batchCache fetchManagedObjects];
        
        NSDictionary *relationshipCaches = [batchCache generateRelationshipCaches];

        for (int j = 0; j < [batchCache count]; j++) {
            
//            if (JC_LOGGING_ENABLED)
//                NSLog(@"Starting import of object %d of %d, in batch %d of %d for entity %@", j, [batchCache count], i, numberOfBatches, [[batchCache entity] name]);
            
            JCProxyObject *proxyObject = [batchCache proxyObjectAtIndex:j];
            
            [proxyObject updateAttributes];
            [proxyObject updateInverseRelationships];
            
            NSEntityDescription *entity = [proxyObject entity];
            NSArray *relationships = [[entity relationshipsByName] allKeys];
            
            for (NSString *relationshipName in relationships) {
                
                JCProxyObjectCache *relationshipCache = [relationshipCaches objectForKey:relationshipName];
                [relationshipCache fetchManagedObjects];
                [proxyObject updateRelationship:relationshipName fromManagedObjectCache:relationshipCache];
            }
            
            [managedObjects addObject:[[proxyObject managedObject] objectID]];
            
            if (i > 0 && useSaveBatching && (i % saveBatchSize == 0)) {
                [self.managedObjectContext save:nil];
            }
        }
        
        for (JCProxyObjectCache *relationshipCache in [relationshipCaches allValues])
            [self managedObjectIDsFromCache:relationshipCache];
        
        if (useImportBatching) {
            
            [self.managedObjectContext save:nil];

            if (self.resetManagedObjectContext)
                [self.managedObjectContext reset];
        }
        
        [pool drain];
    }
    
    [batches release];
    
    return [managedObjects autorelease];
}

@end


            if (self.resetManagedObjectContext)
                [self.managedObjectContext reset];
        }
        
        [pool drain];
    }
    
    [batches release];
    
    return [managedObjects autorelease];
}

@end
