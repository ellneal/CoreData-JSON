//
//  JCProxyObject.m
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

#import "JCProxyObject.h"

#import "JCMappingModel.h"
#import "JCProxyObjectCache.h"

#import "ConvenienceCategories.h"


@interface JCProxyObject () {
    
    NSBundle *_bundle;
    JCMappingModel *_mappingModel;
    
    NSMutableDictionary *_inverseRelationships;
}

@property (nonatomic, readonly) NSBundle *bundle;
@property (nonatomic, readonly) JCMappingModel *mappingModel;

@end


@implementation JCProxyObject

@synthesize entity = _entity;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize uniqueFieldValue = _uniqueFieldValue;
@synthesize superUniqueFieldValue = _superUniqueFieldValue;
@synthesize jsonObject = _jsonObject;
@synthesize managedObject = _managedObject;
@synthesize bundle = _bundle;


- (id)initWithEntity:(NSEntityDescription *)entity inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext uniqueFieldValue:(id)uniqueFieldValue superUniqueFieldValue:(id)superUniqueFieldValue jsonObject:(id)jsonObject bundle:(NSBundle *)bundleOrNil {
    
    self = [super init];
    
    if (self) {

        _entity = [entity retain];
        _managedObjectContext = [managedObjectContext retain];
        _uniqueFieldValue = [uniqueFieldValue retain];
        _superUniqueFieldValue = [superUniqueFieldValue retain];
        _jsonObject = [jsonObject retain];
        _bundle = [bundleOrNil retain];
        
        _inverseRelationships = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    
    [_entity release];
    [_managedObjectContext release];
    [_uniqueFieldValue release];
    [_superUniqueFieldValue release];
    [_jsonObject release];
    [_managedObject release];
    [_bundle release];
    [_mappingModel release];
    
    [_inverseRelationships release];
    
    [super dealloc];
}


#pragma mark - Managed Object Generation

- (void)generateManagedObject {
    
    if (self.managedObject != nil)
        return;
    
    _managedObject = [[NSManagedObject alloc] initWithEntity:self.entity insertIntoManagedObjectContext:self.managedObjectContext];
    
    NSString *uniqueFieldName = [self.mappingModel uniqueField];
    [_managedObject setValue:[self uniqueFieldValue] forKey:uniqueFieldName];
}


#pragma mark - Inverse Relationships

- (void)addManagedObject:(NSManagedObject *)managedObject forInverseRelationship:(NSString *)relationshipName {
    
    NSMutableArray *managedObjectIDs = [_inverseRelationships objectForKey:relationshipName];

    if (managedObjectIDs == nil) {
        managedObjectIDs = [[NSMutableArray alloc] init];
        [_inverseRelationships setObject:managedObjectIDs forKey:relationshipName];
        [managedObjectIDs release];
    }
    
    [managedObjectIDs addObject:[managedObject objectID]];
}


#pragma mark - Updating

- (void)updateAttributes {
    
    if (self.managedObject == nil)
        [self generateManagedObject];
    
    //if this object is just a uniqueFieldValue, don't do anything
    if (![[self jsonObject] isKindOfClass:[NSDictionary class]])
        return;
    
    NSDictionary *attributes = [self.entity attributesByNameIncludedInMappingModel:self.mappingModel];
    NSArray *coreDataAttributes = [attributes allKeys];
    
    for (NSString *attribute in coreDataAttributes) {
		
        if ([attribute isEqualToString:[self.mappingModel uniqueField]])
            continue;
        
		NSString *mappedKey = [self.mappingModel.propertiesMap objectForKey:attribute];
		
		id newValue = [self.mappingModel valueForMappedPropertyName:mappedKey fromDictionary:self.jsonObject withSuperUniqueFieldValue:self.superUniqueFieldValue];
        
        //if nil is returned, don't do anything (i.e. not included in provided data)
        if (newValue == nil)
            continue;
        //convert null to nil to erase the attribute value
        if (newValue == [NSNull null])
            newValue = nil;
        
		newValue = [self.mappingModel transformedValue:newValue forPropertyName:attribute];
		
		[self.managedObject setValue:newValue forKey:attribute];
	}
}

- (void)updateRelationship:(NSString *)relationshipName fromManagedObjectCache:(JCProxyObjectCache *)managedObjectCache {
    
    if (self.managedObject == nil)
        [self generateManagedObject];
    
    //if this object is just a uniqueFieldValue, don't do anything
    if (![[self jsonObject] isKindOfClass:[NSDictionary class]])
        return;
    
    NSRelationshipDescription *relationship = [[self.entity relationshipsByName] objectForKey:relationshipName];
    NSString *mappedKey = [self.mappingModel.propertiesMap objectForKey:relationshipName];
    
    id newValue = [self.mappingModel valueForMappedPropertyName:mappedKey fromDictionary:self.jsonObject];
    
    //if nil is returned, don't do anything (i.e. not included in provided data)
    if (newValue == nil)
        return;
    //convert null to nil to erase the attribute value
    if (newValue == [NSNull null])
        newValue = nil;
    
    newValue = [self.mappingModel transformedValue:newValue forPropertyName:relationshipName];
    
    if (newValue != nil) {
        
        if ([relationship isToMany]) {
			
			if (![newValue isKindOfClass:[NSArray class]])
				[NSException raise:@"JCInvalidToManyRelationshipException" format:@"To-many relationships must be represented by an array."];
            
            NSArray *relationshipJSONObjects = newValue;
            NSMutableSet *managedObjects = [[NSMutableSet alloc] initWithCapacity:[relationshipJSONObjects count]];
            
            for (id jsonObject in relationshipJSONObjects) {
                
                id uniqueFieldValue = [managedObjectCache uniqueFieldValueForJSONObject:jsonObject superUniqueFieldValue:[self uniqueFieldValue]];
                
                JCProxyObject *proxyObject = [managedObjectCache proxyObjectForUniqueFieldValue:uniqueFieldValue];
                NSManagedObject *managedObject = [proxyObject managedObject];
                
                if (managedObject != nil)
                    [managedObjects addObject:managedObject];
                else
                    [proxyObject addManagedObject:[self managedObject] forInverseRelationship:[[relationship inverseRelationship] name]];
            }
            
            newValue = [managedObjects autorelease];
        }
        else {
            
            id jsonObject = newValue;
            id uniqueFieldValue = [managedObjectCache uniqueFieldValueForJSONObject:jsonObject superUniqueFieldValue:[self uniqueFieldValue]];
            
            JCProxyObject *proxyObject = [managedObjectCache proxyObjectForUniqueFieldValue:uniqueFieldValue];
            NSManagedObject *managedObject = [proxyObject managedObject];
            
            if (managedObject != nil) {
                newValue = managedObject;
            }
            else {
                newValue = nil;
                [proxyObject addManagedObject:[self managedObject] forInverseRelationship:[[relationship inverseRelationship] name]];
            }
        }
    }
    
    [self.managedObject setValue:newValue forKey:relationshipName];
}

- (void)updateInverseRelationships {
    
    for (NSString *relationshipName in [_inverseRelationships allKeys]) {
        
        NSRelationshipDescription *relationship = [[self.entity relationshipsByName] objectForKey:relationshipName];
        NSArray *managedObjectIDs = [_inverseRelationships objectForKey:relationshipName];

        if ([relationship isToMany]) {
            
            NSMutableSet *relationshipObjects = [[NSMutableSet alloc] initWithCapacity:[managedObjectIDs count]];
            
            for (NSManagedObjectID *managedObjectID in managedObjectIDs) {
                NSManagedObject *managedObject = [self.managedObjectContext objectWithID:managedObjectID];
                [relationshipObjects addObject:managedObject];
            }
            
            [[self managedObject] setValue:relationshipObjects forKey:relationshipName];
            [relationshipObjects release];
        }
        else {
            
            for (NSManagedObjectID *managedObjectID in managedObjectIDs) {
                NSManagedObject *managedObject = [self.managedObjectContext objectWithID:managedObjectID];
                [[self managedObject] setValue:managedObject forKey:relationshipName];
            }
        }
    }
    
    [_inverseRelationships release];
    _inverseRelationships = [[NSMutableDictionary alloc] init];
}


#pragma mark - Lazily Loaded Objects

- (JCMappingModel *)mappingModel {
    
    if (_mappingModel != nil)
        return _mappingModel;
    
    _mappingModel = [[JCMappingModel mappingModelForEntity:self.entity bundle:self.bundle] retain];
    
    return _mappingModel;
}

@end
