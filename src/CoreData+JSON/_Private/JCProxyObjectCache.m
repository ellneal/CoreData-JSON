//
//  JCMManagedCache.m
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

#import "JCProxyObjectCache.h"

#import "JCMappingModel.h"
#import "JCProxyObject.h"

#import "ConvenienceCategories.h"


@interface JCProxyObjectCache () {
    
    NSBundle *_bundle;
    
    NSManagedObjectContext *_managedObjectContext;
    NSEntityDescription *_entity;
    JCMappingModel *_mappingModel;
    
    NSMutableArray *_proxyObjects;
}

- (id)initWithEntity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext proxyObjects:(NSArray *)proxyObjects bundle:(NSBundle *)bundleOrNil;

@property (nonatomic, readonly) NSBundle *bundle;

@property (nonatomic, readonly) JCMappingModel *mappingModel;


- (NSArray *)uniqueFieldValuesFromJSONObjects:(NSArray *)jsonObjects superUniqueFieldValue:(id)superUniqueFieldValue;
- (NSArray *)fetchManagedObjectsWithUniqueFieldValues:(NSArray *)uniqueFieldValues;


@end


@implementation JCProxyObjectCache

@synthesize managedObjectContext = _managedObjectContext;
@synthesize entity = _entity;
@synthesize bundle = _bundle;

- (id)initWithEntity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext bundle:(NSBundle *)bundleOrNil {
    
    self = [super init];
    
    if (self) {
        _entity = [entity retain];
        _managedObjectContext = [managedObjectContext retain];
        _bundle = [bundleOrNil retain];
        
        _proxyObjects = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id)initWithEntity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext proxyObjects:(NSArray *)proxyObjects bundle:(NSBundle *)bundleOrNil {
    
    self = [super init];
    
    if (self) {
        _entity = [entity retain];
        _managedObjectContext = [managedObjectContext retain];
        
        _proxyObjects = [[NSMutableArray alloc] initWithArray:proxyObjects];
    }
    
    return self;
}

- (void)dealloc {
    
    [_bundle release];
    
    [_entity release];
    [_managedObjectContext release];
    [_mappingModel release];
    
    [super dealloc];
}


#pragma mark - Get/Set Managed Objects

- (JCProxyObject *)proxyObjectForUniqueFieldValue:(id)uniqueFieldValue {
    
    for (JCProxyObject *proxyObject in _proxyObjects) {
        if ([[proxyObject uniqueFieldValue] isEqual:uniqueFieldValue])
            return proxyObject;
    }
    
    return nil;
}

- (void)addProxyObject:(JCProxyObject *)proxyObject {
    
//    if ([_proxyObjects containsObject:proxyObject])
//        return;
    
    [_proxyObjects addObject:proxyObject];
}


- (void)addProxyObjectsFromJSONObjects:(NSArray *)jsonObjects superUniqueFieldValue:(id)superUniqueFieldValue {
    
    for (id jsonObject in jsonObjects) {
        
        id uniqueFieldValue = [self uniqueFieldValueForJSONObject:jsonObject superUniqueFieldValue:superUniqueFieldValue];
        
        JCProxyObject *proxyObject = [[JCProxyObject alloc] initWithEntity:self.entity inManagedObjectContext:self.managedObjectContext uniqueFieldValue:uniqueFieldValue superUniqueFieldValue:superUniqueFieldValue jsonObject:jsonObject bundle:self.bundle];
        
        [self addProxyObject:proxyObject];
        [proxyObject release];
    }
}

- (void)fetchManagedObjects {
    
    NSArray *uniqueFieldValues = [[self uniqueFieldValues] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *fetchedObjects = [self fetchManagedObjectsWithUniqueFieldValues:uniqueFieldValues];
    
    NSString *uniqueFieldName = [self.mappingModel uniqueField];
    
    // these iterations pick out missing objects by stepping through each array
    // 1. get the next unique field value & managed object
    // 2. check if the unique field value matches the managed object
    // 3. if they do, increment both indexes
    // 4. if they don't, create a new managed object and DO NOT increment the fetched object index
    // 5. add the managed object to the cache
    // 6. get the next unique field value and check if it matches the last fetched object
    NSUInteger uniqueFieldIndex = 0;
    NSUInteger fetchedObjectIndex = 0;
    for (uniqueFieldIndex = 0; uniqueFieldIndex < [uniqueFieldValues count]; uniqueFieldIndex++) {
        
        id uniqueFieldValue = [uniqueFieldValues objectAtIndex:uniqueFieldIndex];
        JCProxyObject *proxyObject = [self proxyObjectForUniqueFieldValue:uniqueFieldValue];
        
        NSManagedObject *managedObject = nil;
        
        if ([fetchedObjects count] > fetchedObjectIndex) {
            
            managedObject = [fetchedObjects objectAtIndex:fetchedObjectIndex];
            id managedObjectUniqueFieldValue = [managedObject valueForKey:uniqueFieldName];
            
            if ([uniqueFieldValue isEqual:managedObjectUniqueFieldValue]) {
                fetchedObjectIndex++;
            }
        }
        
        [proxyObject setManagedObject:managedObject];
    }
}

- (NSArray *)uniqueFieldValuesFromJSONObjects:(NSArray *)jsonObjects superUniqueFieldValue:(id)superUniqueFieldValue {
    
    NSMutableArray *uniqueFieldValues = [NSMutableArray arrayWithCapacity:[jsonObjects count]];
    
    for (id jsonObject in jsonObjects)
        [uniqueFieldValues addObject:[self uniqueFieldValueForJSONObject:jsonObject superUniqueFieldValue:superUniqueFieldValue]];
    
    return uniqueFieldValues;
}

- (id)uniqueFieldValueForJSONObject:(id)jsonObject superUniqueFieldValue:(id)superUniqueFieldValue {
    
    id uniqueFieldValue = nil;
    
    NSString *mappedUniqueFieldName = [self.mappingModel.propertiesMap objectForKey:[self.mappingModel uniqueField]];
    
    if ([jsonObject isKindOfClass:[NSDictionary class]])
        uniqueFieldValue = [self.mappingModel valueForMappedPropertyName:mappedUniqueFieldName fromDictionary:jsonObject withSuperUniqueFieldValue:superUniqueFieldValue];
    else
        uniqueFieldValue = jsonObject;
    
    uniqueFieldValue = [self.mappingModel transformedValue:uniqueFieldValue forPropertyName:[self.mappingModel uniqueField]];
    
    return uniqueFieldValue;
}

- (NSArray *)fetchManagedObjectsWithUniqueFieldValues:(NSArray *)uniqueFieldValues {
    
    NSString *uniqueFieldName = [self.mappingModel uniqueField];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:self.entity];
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


#pragma mark - Relationships

- (NSDictionary *)generateRelationshipCaches {
    
    NSArray *relationships = [[self.entity relationshipsByNameIncludedInMappingModel:self.mappingModel] allKeys];
    NSMutableDictionary *caches = [[NSMutableDictionary alloc] initWithCapacity:[relationships count]];
    
    for (NSRelationshipDescription *relationshipName in relationships) {
        
        NSRelationshipDescription *relationship = [[self.entity relationshipsByName] objectForKey:relationshipName];
        NSEntityDescription *destinationEntity = [relationship destinationEntity];
        NSString *mappedRelationshipName = [self.mappingModel.propertiesMap objectForKey:relationshipName];
        
        JCProxyObjectCache *relationshipCache = [[JCProxyObjectCache alloc] initWithEntity:destinationEntity managedObjectContext:self.managedObjectContext bundle:self.bundle];
        
        for (JCProxyObject *proxyObject in _proxyObjects) {
            
            id jsonObject = [proxyObject jsonObject];
            
            if (![jsonObject isKindOfClass:[NSDictionary class]])
                continue;
            
            id superUniqueFieldValue = [proxyObject uniqueFieldValue];
            id relationshipValue = [jsonObject objectForKey:mappedRelationshipName];
            
            if (relationshipValue == nil)
                continue;
            
            if ([relationship isToMany]) {
                
                NSArray *relationshipJSONObjects = relationshipValue;
                [relationshipCache addProxyObjectsFromJSONObjects:relationshipJSONObjects superUniqueFieldValue:superUniqueFieldValue];
            }
            else {
                
                id jsonObject = relationshipValue;
                id uniqueFieldValue = [relationshipCache uniqueFieldValueForJSONObject:jsonObject superUniqueFieldValue:superUniqueFieldValue];
                
                JCProxyObject *proxyObject = [[JCProxyObject alloc] initWithEntity:destinationEntity inManagedObjectContext:self.managedObjectContext uniqueFieldValue:uniqueFieldValue superUniqueFieldValue:superUniqueFieldValue jsonObject:jsonObject bundle:self.bundle];
                [relationshipCache addProxyObject:proxyObject];
                [proxyObject release];
            }
        }
        
        if ([relationshipCache count] > 0)
            [caches setObject:relationshipCache forKey:relationshipName];
        
        [relationshipCache release];
    }
    
    return [caches autorelease];
}


#pragma mark - Lazy Properties

- (JCMappingModel *)mappingModel {
    
    if (_mappingModel != nil)
        return _mappingModel;
    
    _mappingModel = [[JCMappingModel mappingModelForEntity:self.entity bundle:self.bundle] retain];
    
    return _mappingModel;
}


#pragma mark - Array Stuff

- (NSUInteger)count {
    return [_proxyObjects count];
}

- (JCProxyObject *)proxyObjectAtIndex:(NSUInteger)index {
    return [_proxyObjects objectAtIndex:index];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len {
    return [_proxyObjects countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (JCProxyObjectCache *)subcacheWithRange:(NSRange)range {
    
    NSArray *proxyObjects = [_proxyObjects subarrayWithRange:range];
    
    return [[[JCProxyObjectCache alloc] initWithEntity:self.entity managedObjectContext:self.managedObjectContext proxyObjects:proxyObjects bundle:self.bundle] autorelease];
}

- (NSArray *)uniqueFieldValues {
    
    NSMutableArray *uniqueFieldValues = [[NSMutableArray alloc] initWithCapacity:[_proxyObjects count]];
    for (JCProxyObject *proxyObject in _proxyObjects)
        [uniqueFieldValues addObject:[proxyObject uniqueFieldValue]];
    return [uniqueFieldValues autorelease];
}

- (NSArray *)jsonObjects {
    
    NSMutableArray *jsonObjects = [[NSMutableArray alloc] initWithCapacity:[_proxyObjects count]];
    for (JCProxyObject *proxyObject in _proxyObjects)
        [jsonObjects addObject:[proxyObject jsonObject]];
    return [jsonObjects autorelease];
}

- (NSArray *)managedObjects {
    
    NSMutableArray *managedObjects = [[NSMutableArray alloc] initWithCapacity:[_proxyObjects count]];
    for (JCProxyObject *proxyObject in _proxyObjects) {
        NSManagedObject *managedObject = [proxyObject managedObject];
        if (managedObject != nil)
            [managedObjects addObject:managedObject];
    }
    return [managedObjects autorelease];
}

@end
