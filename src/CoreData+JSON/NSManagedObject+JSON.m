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
#import "JSON.h"

@interface NSManagedObject (JSONPrivate)

+ (id)managedObjectWithJSON:(NSString *)json entity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext bundle:(NSBundle *)bundleOrNil;
+ (id)managedObjectWithDictionary:(NSDictionary *)values entity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext bundle:(NSBundle *)bundleOrNil;

- (void)setAttributesFromDictionary:(NSDictionary *)dictionary mappingModel:(JCMappingModel *)mappingModel;
- (void)setRelationshipsFromDictionary:(NSDictionary *)dictionary mappingModel:(JCMappingModel *)mappingModel bundle:(NSBundle *)bundleOrNil;

- (void)setValue:(id)value forRelationship:(NSString *)relationship bundle:(NSBundle *)bundleOrNil;
- (id)managedObjectWithDictionaryOrUniqueFieldValue:(id)value forEntity:(NSEntityDescription *)entity bundle:(NSBundle *)bundleOrNil;

- (NSString *)JSONRepresentationWithBundle:(NSBundle *)bundleOrNil;
- (NSString *)JSONRepresentationWithToManyBehaviour:(JSONRelationshipMappingBehaviour)toManyBehaviour toOneBehaviour:(JSONRelationshipMappingBehaviour)toOneBehaviour bundle:(NSBundle *)bundleOrNil;

@end

@implementation NSManagedObject (JSON)

+ (id)managedObjectWithJSON:(NSString *)json entity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	
	return [self managedObjectWithJSON:json entity:entity managedObjectContext:managedObjectContext bundle:nil];
}

+ (id)managedObjectWithJSON:(NSString *)json entity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext bundle:(NSBundle *)bundleOrNil {
	
	NSDictionary *jsonValues = [json JSONValue];
	
	return [self managedObjectWithDictionary:jsonValues entity:entity managedObjectContext:managedObjectContext bundle:bundleOrNil];
}

+ (id)managedObjectWithDictionary:(NSDictionary *)values entity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	
	return [self managedObjectWithDictionary:values entity:entity managedObjectContext:managedObjectContext bundle:nil];
}

+ (id)managedObjectWithDictionary:(NSDictionary *)values entity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext bundle:(NSBundle *)bundleOrNil {
	
	JCMappingModel *mappingModel = [JCMappingModel mappingModelWithEntity:entity bundle:bundleOrNil];
	NSString *coreDataUniqueFieldName = mappingModel.uniqueField;
	NSDictionary *propertiesMap = mappingModel.propertiesMap;
	NSString *mappedUniqueFieldName = [propertiesMap objectForKey:coreDataUniqueFieldName];
	id uniqueFieldValue = [mappingModel valueForMappedKey:mappedUniqueFieldName fromDictionary:values];
	id transformedUniqueFieldValue = [mappingModel transformedValue:uniqueFieldValue forPropertyName:coreDataUniqueFieldName];
	
	id managedObject = [managedObjectContext fetchOrInsertManagedObjectForEntity:entity withAttribute:coreDataUniqueFieldName equalTo:transformedUniqueFieldValue];
	
	[managedObject setAttributesFromDictionary:values mappingModel:mappingModel];
	[managedObject setRelationshipsFromDictionary:values mappingModel:mappingModel bundle:bundleOrNil];
	
	return managedObject;
}


- (void)setAttributesFromDictionary:(NSDictionary *)dictionary mappingModel:(JCMappingModel *)mappingModel {
	
	NSDictionary *attributes = [[self entity] attributesByNameIncludedInMappingModel:mappingModel];
	NSArray *coreDataAttributes = [attributes allKeys];
	
	for (NSString *attribute in coreDataAttributes) {
		
		NSString *mappedKey = [mappingModel.propertiesMap objectForKey:attribute];
		
		id newValue = [mappingModel valueForMappedKey:mappedKey fromDictionary:dictionary];
		newValue = [mappingModel transformedValue:newValue forPropertyName:attribute];
		
		[self setValue:newValue forKey:attribute];
	}
}

- (void)setRelationshipsFromDictionary:(NSDictionary *)dictionary mappingModel:(JCMappingModel *)mappingModel bundle:(NSBundle *)bundleOrNil {
	
	NSDictionary *relationships = [[self entity] relationshipsByNameIncludedInMappingModel:mappingModel];
	NSArray *coreDataRelationships = [relationships allKeys];
	
	for (NSString *relationship in coreDataRelationships) {
		
		NSString *mappedKey = [mappingModel.propertiesMap objectForKey:relationship];
		
		id newValue = [mappingModel valueForMappedKey:mappedKey fromDictionary:dictionary];
		newValue = [mappingModel transformedValue:newValue forPropertyName:relationship];
		[self setValue:newValue forRelationship:relationship bundle:bundleOrNil];
	}
}

- (void)setValue:(id)value forRelationship:(NSString *)relationship bundle:bundleOrNil {
	
	id newValue = value;
	
	if (value != nil) {
		
		NSRelationshipDescription *relationshipDescription = [[[self entity] relationshipsByName] objectForKey:relationship];
		NSEntityDescription *destinationEntity = [relationshipDescription destinationEntity];
		
		if ([relationshipDescription isToMany]) {
			
			if (![value isKindOfClass:[NSArray class]])
				[NSException raise:@"InvalidToManyRelationship" format:@"To-many relationships must be represented by an array."];
			
			NSMutableSet *relationshipValues = [[NSMutableSet alloc] initWithCapacity:[value count]];
			
			for (id subValue in value) {
				
				NSManagedObject *newManagedObject = [self managedObjectWithDictionaryOrUniqueFieldValue:subValue forEntity:destinationEntity bundle:nil];
				
				[relationshipValues addObject:newManagedObject];
			}
			
			newValue = [NSSet setWithSet:relationshipValues];
			[relationshipValues release];
		}
		else {
			
			NSManagedObject *newManagedObject = [self managedObjectWithDictionaryOrUniqueFieldValue:value forEntity:destinationEntity bundle:bundleOrNil];
			
			newValue = newManagedObject;
		}
	}
	
	[self setValue:newValue forKey:relationship];
}

- (id)managedObjectWithDictionaryOrUniqueFieldValue:(id)value forEntity:(NSEntityDescription *)entity bundle:(NSBundle *)bundleOrNil {
	
	id managedObject = nil;
	NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
	
	if ([value isKindOfClass:[NSDictionary class]]) {
		
		managedObject = [NSManagedObject managedObjectWithDictionary:value entity:entity managedObjectContext:managedObjectContext];
	}
	else if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
		
		JCMappingModel *mappingModel = [JCMappingModel mappingModelWithEntity:entity bundle:bundleOrNil];
		NSString *uniqueFieldName = mappingModel.uniqueField;
		id transformedValue = [mappingModel transformedValue:value forPropertyName:uniqueFieldName];
		
		managedObject = [managedObjectContext fetchOrInsertManagedObjectForEntity:entity withAttribute:uniqueFieldName equalTo:transformedValue];
	}
	else {
		
		[NSException raise:@"InvalidRelationshipValue" format:@"Relationship values must be represented by a dictionary of values for the destination entity, or a value for the destination entity's UniqueField."];
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
	
	//TODO: Compute JSON
	return nil;
}

@end
