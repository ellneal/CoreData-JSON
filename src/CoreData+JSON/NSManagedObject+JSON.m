//
//  NSManagedObject+JSON.m
//  CoreData+JSON
//
//	Copyright (c) 2010, emdentec (Elliot Neal)
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

#import "CoreData+JSON.h"
#import "CoreData+JSON_Private.h"
#import "ConvenienceCategories.h"
#import "JSONKit.h"

#import "JCImporter.h"

@interface NSManagedObject (JSONPrivate)

- (void)setAttributesFromDictionary:(NSDictionary *)dictionary mappingModel:(JCMappingModel *)mappingModel superUniqueFieldValue:(id)superUniqueFieldValue;
- (void)setRelationshipsFromDictionary:(NSDictionary *)dictionary mappingModel:(JCMappingModel *)mappingModel uniqueFieldValue:(id)uniqueFieldValue bundle:(NSBundle *)bundleOrNil;

- (void)setValue:(id)value forRelationship:(NSString *)relationship uniqueFieldValue:(id)superUniqueFieldValue bundle:(NSBundle *)bundleOrNil;
- (id)managedObjectWithDictionaryOrUniqueFieldValue:(id)value forEntity:(NSEntityDescription *)entity superUniqueFieldValue:(id)superUniqueFieldValue bundle:(NSBundle *)bundleOrNil;

- (NSString *)JSONRepresentationWithBundle:(NSBundle *)bundleOrNil;
- (NSString *)JSONRepresentationWithToManyBehaviour:(JSONRelationshipMappingBehaviour)toManyBehaviour toOneBehaviour:(JSONRelationshipMappingBehaviour)toOneBehaviour bundle:(NSBundle *)bundleOrNil;

- (NSDictionary *)dictionaryRepresentationWithToManyBehaviour:(JSONRelationshipMappingBehaviour)toManyBehaviour toOneBehaviour:(JSONRelationshipMappingBehaviour)toOneBehaviour bundle:(NSBundle *)bundleOrNil;
- (NSDictionary *)dictionaryRepresentationWithToManyBehaviour:(JSONRelationshipMappingBehaviour)toManyBehaviour toOneBehaviour:(JSONRelationshipMappingBehaviour)toOneBehaviour bundle:(NSBundle *)bundleOrNil excludingRelationship:(NSRelationshipDescription *)excludingRelationship;

@end

@implementation NSManagedObject (JSON)

+ (id)managedObjectWithJSON:(NSString *)json entity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	
	return [self managedObjectWithJSON:json entity:entity managedObjectContext:managedObjectContext superUniqueFieldValue:nil];
}

+ (id)managedObjectWithDictionary:(NSDictionary *)values entity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext bundle:(NSBundle *)bundleOrNil {
	
	return [self managedObjectWithDictionary:values entity:entity managedObjectContext:managedObjectContext superUniqueFieldValue:nil bundle:bundleOrNil];
}

+ (id)managedObjectWithJSON:(NSString *)json entity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext superUniqueFieldValue:(id)superUniqueFieldValue {
	
	return [self managedObjectWithJSON:json entity:entity managedObjectContext:managedObjectContext superUniqueFieldValue:superUniqueFieldValue bundle:nil];
}

+ (id)managedObjectWithJSON:(NSString *)json entity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext superUniqueFieldValue:(id)superUniqueFieldValue bundle:(NSBundle *)bundleOrNil {
	
	NSDictionary *jsonValues = [json objectFromJSONString];
	
	return [self managedObjectWithDictionary:jsonValues entity:entity managedObjectContext:managedObjectContext superUniqueFieldValue:superUniqueFieldValue bundle:bundleOrNil];
}

+ (id)managedObjectWithDictionary:(NSDictionary *)values entity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	
	return [self managedObjectWithDictionary:values entity:entity managedObjectContext:managedObjectContext superUniqueFieldValue:nil];
}

+ (id)managedObjectWithDictionary:(NSDictionary *)values entity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext superUniqueFieldValue:(id)superUniqueFieldValue {
	
	return [self managedObjectWithDictionary:values entity:entity managedObjectContext:managedObjectContext superUniqueFieldValue:superUniqueFieldValue bundle:nil];
}

+ (id)managedObjectWithDictionary:(NSDictionary *)values entity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext superUniqueFieldValue:(id)superUniqueFieldValue bundle:(NSBundle *)bundleOrNil {
	
	JCImporter *importer = [[JCImporter alloc] initWithManagedObjectContext:managedObjectContext bundle:bundleOrNil];
    id result = [importer managedObjectFromDictionary:values forEntity:entity];
    [importer release];
    return result;
    
    JCMappingModel *mappingModel = [JCMappingModel mappingModelForEntity:entity bundle:bundleOrNil];
	NSString *coreDataUniqueFieldName = mappingModel.uniqueField;
	NSDictionary *propertiesMap = mappingModel.propertiesMap;
	NSString *mappedUniqueFieldName = [propertiesMap objectForKey:coreDataUniqueFieldName];
	id uniqueFieldValue = [mappingModel valueForMappedPropertyName:mappedUniqueFieldName fromDictionary:values withSuperUniqueFieldValue:superUniqueFieldValue];
	id transformedUniqueFieldValue = [mappingModel transformedValue:uniqueFieldValue forPropertyName:coreDataUniqueFieldName];
	
	id managedObject = [managedObjectContext fetchOrInsertManagedObjectForEntity:entity withAttribute:coreDataUniqueFieldName equalTo:transformedUniqueFieldValue];
	
	[managedObject setAttributesFromDictionary:values mappingModel:mappingModel superUniqueFieldValue:superUniqueFieldValue];
	[managedObject setRelationshipsFromDictionary:values mappingModel:mappingModel uniqueFieldValue:transformedUniqueFieldValue bundle:bundleOrNil];
	
	return managedObject;
}


- (void)setAttributesFromDictionary:(NSDictionary *)dictionary mappingModel:(JCMappingModel *)mappingModel superUniqueFieldValue:(id)superUniqueFieldValue {
	
	NSDictionary *attributes = [[self entity] attributesByNameIncludedInMappingModel:mappingModel];
	NSArray *coreDataAttributes = [attributes allKeys];
	
	for (NSString *attribute in coreDataAttributes) {
		
		NSString *mappedKey = [mappingModel.propertiesMap objectForKey:attribute];
		
		id newValue = [mappingModel valueForMappedPropertyName:mappedKey fromDictionary:dictionary withSuperUniqueFieldValue:superUniqueFieldValue];
        
        //if nil is returned, don't do anything
        if (newValue == nil)
            continue;
        //convert null to nil to erase the attribute value
        if (newValue == [NSNull null])
            newValue = nil;
        
		newValue = [mappingModel transformedValue:newValue forPropertyName:attribute];
		
		[self setValue:newValue forKey:attribute];
	}
}

- (void)setRelationshipsFromDictionary:(NSDictionary *)dictionary mappingModel:(JCMappingModel *)mappingModel uniqueFieldValue:(id)uniqueFieldValue bundle:(NSBundle *)bundleOrNil {
	
	NSDictionary *relationships = [[self entity] relationshipsByNameIncludedInMappingModel:mappingModel];
	NSArray *coreDataRelationships = [relationships allKeys];
	
	for (NSString *relationship in coreDataRelationships) {
		
		NSString *mappedKey = [mappingModel.propertiesMap objectForKey:relationship];
		
		id newValue = [mappingModel valueForMappedPropertyName:mappedKey fromDictionary:dictionary];
        
        //if nil is returned, don't do anything
        if (newValue == nil)
            continue;
        //convert null to nil to erase the attribute value
        if (newValue == [NSNull null])
            newValue = nil;
        
		newValue = [mappingModel transformedValue:newValue forPropertyName:relationship];
        
		[self setValue:newValue forRelationship:relationship uniqueFieldValue:uniqueFieldValue bundle:bundleOrNil];
	}
}

- (void)setValue:(id)value forRelationship:(NSString *)relationship uniqueFieldValue:(id)uniqueFieldValue bundle:(NSBundle *)bundleOrNil {
	
	id newValue = value;
	
	if (value != nil) {
		
		NSRelationshipDescription *relationshipDescription = [[[self entity] relationshipsByName] objectForKey:relationship];
		NSEntityDescription *destinationEntity = [relationshipDescription destinationEntity];
		
		if ([relationshipDescription isToMany]) {
			
			if (![value isKindOfClass:[NSArray class]])
				[NSException raise:@"JCInvalidToManyRelationshipException" format:@"To-many relationships must be represented by an array."];
			
			NSMutableSet *relationshipValues = [[NSMutableSet alloc] initWithCapacity:[value count]];
			
			for (id subValue in value) {
                
				NSManagedObject *newManagedObject = [self managedObjectWithDictionaryOrUniqueFieldValue:subValue forEntity:destinationEntity superUniqueFieldValue:uniqueFieldValue bundle:bundleOrNil];
				
				[relationshipValues addObject:newManagedObject];
			}
			
			newValue = [NSSet setWithSet:relationshipValues];
			[relationshipValues release];
		}
		else {
			
			NSManagedObject *newManagedObject = [self managedObjectWithDictionaryOrUniqueFieldValue:value forEntity:destinationEntity superUniqueFieldValue:uniqueFieldValue bundle:bundleOrNil];
			
			newValue = newManagedObject;
		}
	}
	
	[self setValue:newValue forKey:relationship];
}

- (id)managedObjectWithDictionaryOrUniqueFieldValue:(id)value forEntity:(NSEntityDescription *)entity superUniqueFieldValue:(id)superUniqueFieldValue bundle:(NSBundle *)bundleOrNil {
	
	id managedObject = nil;
	NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
	
	if ([value isKindOfClass:[NSDictionary class]]) {
		
		managedObject = [NSManagedObject managedObjectWithDictionary:value entity:entity managedObjectContext:managedObjectContext superUniqueFieldValue:superUniqueFieldValue bundle:bundleOrNil];
	}
	else if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
		
		JCMappingModel *mappingModel = [JCMappingModel mappingModelForEntity:entity bundle:bundleOrNil];
		NSString *uniqueFieldName = mappingModel.uniqueField;
		id transformedValue = [mappingModel transformedValue:value forPropertyName:uniqueFieldName];
		
		managedObject = [managedObjectContext fetchOrInsertManagedObjectForEntity:entity withAttribute:uniqueFieldName equalTo:transformedValue];
	}
	else {
		
		[NSException raise:@"JCInvalidRelationshipValueException" format:@"Relationship values must be represented by a dictionary of values for the destination entity, or a value for the destination entity's UniqueField."];
	}
	
	return managedObject;
}

- (NSString *)JSONRepresentation {
	
	return [self JSONRepresentationWithBundle:nil];
}

- (NSString *)JSONRepresentationWithBundle:(NSBundle *)bundleOrNil {
	
	return [self JSONRepresentationWithToManyBehaviour:JSONRelationshipMappingDoNotMap toOneBehaviour:JSONRelationshipMappingMapUsingUniqueField bundle:bundleOrNil];
}

- (NSString *)JSONRepresentationWithToManyBehaviour:(JSONRelationshipMappingBehaviour)toManyBehaviour toOneBehaviour:(JSONRelationshipMappingBehaviour)toOneBehaviour {
	
	return [self JSONRepresentationWithToManyBehaviour:toManyBehaviour toOneBehaviour:toOneBehaviour bundle:nil];
}

- (NSString *)JSONRepresentationWithToManyBehaviour:(JSONRelationshipMappingBehaviour)toManyBehaviour toOneBehaviour:(JSONRelationshipMappingBehaviour)toOneBehaviour bundle:(NSBundle *)bundleOrNil {
	
	return [[self dictionaryRepresentationWithToManyBehaviour:toManyBehaviour toOneBehaviour:toOneBehaviour bundle:bundleOrNil] JSONString];
}
/*
- (NSDictionary *)dictionaryRepresentationWithToManyBehaviour:(JSONRelationshipMappingBehaviour)toManyBehaviour toOneBehaviour:(JSONRelationshipMappingBehaviour)toOneBehaviour bundle:(NSBundle *)bundleOrNil {
	
	return [self dictionaryRepresentationWithToManyBehaviour:toManyBehaviour toOneBehaviour:toOneBehaviour bundle:bundleOrNil excludingRelationship:nil];
}

- (NSDictionary *)dictionaryRepresentationWithToManyBehaviour:(JSONRelationshipMappingBehaviour)toManyBehaviour toOneBehaviour:(JSONRelationshipMappingBehaviour)toOneBehaviour bundle:(NSBundle *)bundleOrNil excludingRelationship:(NSRelationshipDescription *)excludedRelationship {
	
	JCMappingModel *mappingModel = [JCMappingModel mappingModelWithEntity:[self entity] bundle:bundleOrNil];
	NSMutableDictionary *mutableValues = [[NSMutableDictionary alloc] initWithCapacity:[mappingModel.propertiesMap count]];
	
	[mutableValues addEntriesFromDictionary:[self dictionaryValuesForAttributesFromMappingModel:mappingModel]];
	[mutableValues addEntriesFromDictionary:[self dictionaryValuesForRelationshipsFromMappingModel:mappingModel toManyBehaviour:toManyBehaviour toOneBehaviour:toOneBehaviour excludingRelationship:excludedRelationship]];
	
	NSDictionary *dictionaryRepresentation = [NSDictionary dictionaryWithDictionary:mutableValues];
	
	[mutableValues release];
	
	return dictionaryRepresentation;
}
							 
- (NSDictionary *)dictionaryValuesForAttributesFromMappingModel:(JCMappingModel *)mappingModel {
	
	NSArray *attributes = [[[self entity] attributesByName] allValues];
	NSMutableDictionary *mutableValues = [[NSMutableDictionary alloc] initWithCapacity:[attributes count]];
	
	for (NSAttributeDescription *attribute in attributes) {
		
		NSString *attributeName = attribute.name;
		
		id value = [mappingModel valueForPropertyName:attributeName fromManagedObject:self];
		value = [mappingModel reverseTransformedValue:value forPropertyName:attributeName];
		
		NSString *mappedPropertyName = [mappingModel.propertiesMap objectForKey:attributeName];
		
		[mutableValues setValue:value forKeyPath:mappedPropertyName];
	}
	
	NSDictionary *result = [NSDictionary dictionaryWithDictionary:mutableValues];
	
	[mutableValues release];
	
	return result;
}

- (NSDictionary *)dictionaryValuesForRelationshipsFromMappingModel:(JCMappingModel *)mappingModel toManyBehaviour:(JSONRelationshipMappingBehaviour)toManyBehaviour toOneBehaviour:(JSONRelationshipMappingBehaviour)toOneBehaviour excludingRelationship:(NSRelationshipDescription *)excludedRelationship {
	
	NSArray *relationships = [[[self entity] relationshipsByName] allValues];
	NSMutableDictionary *mutableValues = [[NSMutableDictionary alloc] initWithCapacity:[relationships count]];
	
	for (NSRelationshipDescription *relationship in relationships) {
		
		if (relationship == excludedRelationship)
			continue;
		
		NSString *relationshipName = relationship.name;
		
		id value = [self valueForRelationship:relationship fromMappingModel:mappingModel toManyBehaviour:toManyBehaviour toOneBehaviour:toOneBehaviour];
		value = [mappingModel reverseTransformedValue:value forPropertyName:relationshipName];
		
		NSString *mappedPropertyName = [mappingModel.propertiesMap objectForKey:relationshipName];
		
		[mutableValues setValue:value forKeyPath:mappedPropertyName];
	}
	
	NSDictionary *result = [NSDictionary dictionaryWithDictionary:mutableValues];
	
	[mutableValues release];
	
	return result;
}

- (id)valueForRelationship:(NSRelationshipDescription *)relationship fromMappingModel:(JCMappingModel *)mappingModel toManyBehaviour:(JSONRelationshipMappingBehaviour)toManyBehaviour toOneBehaviour:(JSONRelationshipMappingBehaviour)toOneBehaviour bundle:(NSBundle *)bundleOrNil {
	
	id value = nil;
	NSString *relationshipName = relationship.name;
	
	if ([relationship isToMany]) {
		
		if (toManyBehaviour == JSONRelationshipMappingMapUsingJSON) {
			
			value = [mappingModel valueForPropertyName:relationshipName fromManagedObject:self];
			
			if ([[relationship inverseRelationship] isToMany]) {
				
				//many-to-many relationship, so map inverse using unique field
				value = [value dictionaryRepresentationWithToManyBehaviour:JSONRelationshipMappingMapUsingUniqueField toOneBehaviour:JSONRelationshipMappingMapUsingUniqueField bundle:bundleOrNil];
			}
			else {
			}
		}
		else if (toManyBehaviour == JSONRelationshipMappingMapUsingUniqueField) {
			
		}
	}
	else {
		
	}
	
	return nil;
}
 */

@end
