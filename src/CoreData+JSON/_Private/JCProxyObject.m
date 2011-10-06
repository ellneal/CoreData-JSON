//
//  JCManagedObject.m
//  CoreData+JSON
//
//  Created by Elliot Neal on 05/10/2011.
//  Copyright 2011 emdentec. All rights reserved.
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
            
            NSManagedObject *managedObject = [[managedObjectCache proxyObjectForUniqueFieldValue:uniqueFieldValue] managedObject];
            newValue = managedObject;
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
