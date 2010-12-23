//
//  NSManagedObject+JSON_Tests.m
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

#import "NSManagedObject+JSON_Tests.h"
#import "NSManagedObjectContext+UnitTesting.h"

#import "NSManagedObject+JSON.h"
#import "NSManagedObjectContext+JSON.h"

#import "NSEntityDescription+JC.h"

#import "JCMappingModel.h"

#import "TestToDateValueTransformer.h"
#import "TestNumberToStringTransformer.h"

@interface NSManagedObject (JSONPrivateRedeclare)

+ (id)managedObjectWithJSON:(NSString *)json entity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext bundle:(NSBundle *)bundleOrNil;
+ (id)managedObjectWithDictionary:(NSDictionary *)values entity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext bundle:(NSBundle *)bundleOrNil;

@end

@implementation NSManagedObject_JSON_Tests

- (void)setUp {
	
	bundle = [[NSBundle bundleForClass:[self class]] retain];
	managedObjectContext = [[NSManagedObjectContextUnitTesting inMemoryManagedObjectContextFromBundle:bundle] retain];
	
	testEntity = [[NSEntityDescription entityForName:@"testEntity" inManagedObjectContext:managedObjectContext] retain];
	testRelatedEntity = [[NSEntityDescription entityForName:@"testRelatedEntity" inManagedObjectContext:managedObjectContext] retain];
	
	testEntityUniqueFieldName = [@"uniqueField" retain];
	mappedTestEntityUniqueFieldName = [@"jsonUniqueField" retain];
	testEntityTestAttributeName = [@"testAttribute" retain];
	mappedTestEntityTestAttributeName = [@"jsonTestAttribute" retain];
	testEntityTestToManyRelationshipName = [@"testToManyRelationship" retain];
	mappedTestEntityTestToManyRelationshipName = [@"relatedEntities" retain];
	
	testRelatedEntityUniqueFieldName = [@"uniqueField" retain];
	mappedTestRelatedEntityUniqueFieldName = [@"jsonUniqueField" retain];
	testRelatedEntityTestToOneRelationshipName = [@"testToOneRelationship" retain];
	mappedTestRelatedEntityTestToOneRelationshipName = [@"parentEntity" retain];
	testRelatedEntityTestTransformedAttributeName = [@"testTransformedAttribute" retain];
	mappedTestRelatedEntityTestTransformedAttributeName = [@"jsonTransformedAttribute" retain];
}

- (void)tearDown {
	
	[bundle release];
	[managedObjectContext release];
	
	[testEntity release];
	[testRelatedEntity release];
	
	[testEntityUniqueFieldName release];
	[mappedTestEntityUniqueFieldName release];
	[testEntityTestAttributeName release];
	[mappedTestEntityTestAttributeName release];
	[testEntityTestToManyRelationshipName release];
	[mappedTestEntityTestToManyRelationshipName release];
	
	[testRelatedEntityUniqueFieldName release];
	[mappedTestRelatedEntityUniqueFieldName release];
	[testRelatedEntityTestToOneRelationshipName release];
	[mappedTestRelatedEntityTestToOneRelationshipName release];
	[testRelatedEntityTestTransformedAttributeName release];
	[mappedTestRelatedEntityTestTransformedAttributeName release];
}

- (void)testMaps {
	
	STAssertNoThrow([JCMappingModel mappingModelWithEntity:testEntity bundle:bundle], @"jcmap for testEntity is invalid");
	
	JCMappingModel *mappingModel = nil;
	
	STAssertNoThrow(mappingModel = [JCMappingModel mappingModelWithEntity:testRelatedEntity bundle:bundle], @"jcmap for testRelatedEntity is invalid");
	STAssertNotNil(mappingModel.valueTransformers, nil);
}

- (void)testInsertTestEntityWithDictionaryNoRelationships {
	
	NSString *uniqueFieldValue = @"someUniqueValue";
	NSString *testAttributeValue = @"testAttributeValue";
	
	NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:uniqueFieldValue, mappedTestEntityUniqueFieldName, testAttributeValue, mappedTestEntityTestAttributeName, nil];
	
	NSManagedObject *managedObject = [NSManagedObject managedObjectWithDictionary:values entity:testEntity managedObjectContext:managedObjectContext bundle:bundle];
	
	STAssertNotNil(managedObject, nil);
	STAssertEqualObjects([managedObject valueForKey:testEntityUniqueFieldName], uniqueFieldValue, nil);
	STAssertEqualObjects([managedObject valueForKey:testEntityTestAttributeName], testAttributeValue, nil);
}

- (void)testToManyRelationshipDefinedByUniqueKey {
	
	NSString *uniqueFieldValue = @"someUniqueValue";
	NSString *attributeValue = @"testAttributeValue";
	NSNumber *toManyRelationshipValue = [NSArray arrayWithObjects:[NSNumber numberWithInteger:0], [NSNumber numberWithInteger:1], nil];
	
	NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:uniqueFieldValue, mappedTestEntityUniqueFieldName, attributeValue, mappedTestEntityTestAttributeName, toManyRelationshipValue, mappedTestEntityTestToManyRelationshipName, nil];
	
	NSManagedObject *managedObject = [NSManagedObject managedObjectWithDictionary:values entity:testEntity managedObjectContext:managedObjectContext bundle:bundle];
	
	STAssertNotNil(managedObject, nil);
	STAssertEqualObjects([managedObject valueForKey:testEntityUniqueFieldName], uniqueFieldValue, nil);
	STAssertEqualObjects([managedObject valueForKey:testEntityTestAttributeName], attributeValue, nil);
	
	NSSet *relatedEntities = [managedObject valueForKey:testEntityTestToManyRelationshipName];
	STAssertTrue([relatedEntities count] == 2, nil);
	
	NSManagedObject *relatedManagedObject = [relatedEntities anyObject];
	STAssertNotNil(relatedManagedObject, nil);
	STAssertNotNil([relatedManagedObject valueForKey:testRelatedEntityUniqueFieldName], nil);
}

- (void)testToManyRelationshipDefinedByDictionary {
	
	NSString *uniqueFieldValue = @"someUniqueValue";
	NSString *attributeValue = @"testAttributeValue";
	NSNumber *toManyRelationshipValue = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:0], mappedTestRelatedEntityUniqueFieldName, nil], [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1], mappedTestRelatedEntityUniqueFieldName, nil], nil];
	
	NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:uniqueFieldValue, mappedTestEntityUniqueFieldName, attributeValue, mappedTestEntityTestAttributeName, toManyRelationshipValue, mappedTestEntityTestToManyRelationshipName, nil];
	
	NSManagedObject *managedObject = [NSManagedObject managedObjectWithDictionary:values entity:testEntity managedObjectContext:managedObjectContext bundle:bundle];
	
	STAssertNotNil(managedObject, nil);
	STAssertEqualObjects([managedObject valueForKey:testEntityUniqueFieldName], uniqueFieldValue, nil);
	STAssertEqualObjects([managedObject valueForKey:testEntityTestAttributeName], attributeValue, nil);
	
	NSSet *relatedEntities = [managedObject valueForKey:testEntityTestToManyRelationshipName];
	STAssertTrue([relatedEntities count] == 2, nil);
	
	NSManagedObject *relatedManagedObject = [relatedEntities anyObject];
	STAssertNotNil(relatedManagedObject, nil);
	STAssertNotNil([relatedManagedObject valueForKey:testRelatedEntityUniqueFieldName], nil);
}

- (void)testToOneRelationshipDefinedByUniqueKey {
	
	NSNumber *uniqueFieldValue = [NSNumber numberWithInteger:0];
	NSString *toOneRelationshipValue = @"someUniqueValue";
	
	NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:uniqueFieldValue, mappedTestRelatedEntityUniqueFieldName, toOneRelationshipValue, mappedTestRelatedEntityTestToOneRelationshipName, nil];
	
	NSManagedObject *managedObject = [NSManagedObject managedObjectWithDictionary:values entity:testRelatedEntity managedObjectContext:managedObjectContext bundle:bundle];
	
	STAssertNotNil(managedObject, nil);
	STAssertEqualObjects([managedObject valueForKey:testRelatedEntityUniqueFieldName], uniqueFieldValue, nil);
	
	NSManagedObject *relatedObject = [managedObject valueForKey:testRelatedEntityTestToOneRelationshipName];
	
	STAssertNotNil(relatedObject, nil);
	STAssertEqualObjects([relatedObject valueForKey:testEntityUniqueFieldName], toOneRelationshipValue, nil);
}

- (void)testToOneRelationshipDefinedByDictionary {
	
	NSNumber *uniqueFieldValue = [NSNumber numberWithInteger:0];
	NSString *parentEntityUniqueFieldValue = @"someUniqueValue";
	NSString *parentEntityAttributeValue = @"someAttributeValue";
	NSDictionary *toOneRelationshipValue = [NSDictionary dictionaryWithObjectsAndKeys:parentEntityUniqueFieldValue, mappedTestEntityUniqueFieldName, parentEntityAttributeValue, mappedTestEntityTestAttributeName, nil];
	
	NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:uniqueFieldValue, mappedTestRelatedEntityUniqueFieldName, toOneRelationshipValue, mappedTestRelatedEntityTestToOneRelationshipName, nil];
	
	NSManagedObject *managedObject = [NSManagedObject managedObjectWithDictionary:values entity:testRelatedEntity managedObjectContext:managedObjectContext bundle:bundle];
	STAssertNotNil(managedObject, nil);
	STAssertEqualObjects([managedObject valueForKey:testRelatedEntityUniqueFieldName], uniqueFieldValue, nil);
	
	NSManagedObject *relatedObject = [managedObject valueForKey:testRelatedEntityTestToOneRelationshipName];
	STAssertNotNil(relatedObject, nil);
	STAssertEqualObjects([relatedObject valueForKey:testEntityUniqueFieldName], parentEntityUniqueFieldValue, nil);
	STAssertEqualObjects([relatedObject valueForKey:testEntityTestAttributeName], parentEntityAttributeValue, nil);
}

- (void)testValueTranformers {
	
	NSNumber *uniqueFieldValue = [NSNumber numberWithInteger:0];
	NSNumber *transformedAttributeValue = [NSNumber numberWithDouble:1292812000];
	
	NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:uniqueFieldValue, mappedTestRelatedEntityUniqueFieldName, transformedAttributeValue, mappedTestRelatedEntityTestTransformedAttributeName, nil];
	
	NSManagedObject *managedObject = [NSManagedObject managedObjectWithDictionary:values entity:testRelatedEntity managedObjectContext:managedObjectContext bundle:bundle];
	STAssertNotNil(managedObject, nil);
	
	NSValueTransformer *equivalentValueTranformer = [[[TestToDateValueTransformer alloc] init] autorelease];
	NSDate *correctTransformedDate = [equivalentValueTranformer transformedValue:transformedAttributeValue];
	STAssertEqualObjects([managedObject valueForKey:testRelatedEntityTestTransformedAttributeName], correctTransformedDate, nil);
}

- (void)testTransformedUniqueField {
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"testTransformedUniqueFieldEntity" inManagedObjectContext:managedObjectContext];
	
	NSString *testTransformedUniqueFieldEntityUniqueFieldName = @"uniqueField";
	NSString *mappedTestTransformedUniqueFieldEntityUniqueFieldName = @"jsonUniqueField";
	NSNumber *uniqueFieldValue = [NSNumber numberWithInteger:0];
	
	NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:uniqueFieldValue, mappedTestTransformedUniqueFieldEntityUniqueFieldName, nil];
	
	NSManagedObject *managedObject = [NSManagedObject managedObjectWithDictionary:values entity:entity managedObjectContext:managedObjectContext bundle:bundle];
	STAssertNotNil(managedObject, nil);
	
	NSValueTransformer *transformer = [[[TestNumberToStringTransformer alloc] init] autorelease];
	NSString *transformedUniqueFieldValue = [transformer transformedValue:uniqueFieldValue];
	STAssertEqualObjects([managedObject valueForKey:testTransformedUniqueFieldEntityUniqueFieldName], transformedUniqueFieldValue, nil);
	
	NSManagedObject *theSameManagedObject = [NSManagedObject managedObjectWithDictionary:values entity:entity managedObjectContext:managedObjectContext bundle:bundle];
	STAssertEquals(managedObject, theSameManagedObject, nil);
}

- (void)testFormatParsing {
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"testExpressionEntity" inManagedObjectContext:managedObjectContext];
	
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"someUniqueValue", @"jsonUniqueField", [NSNumber numberWithInteger:45], @"jsonTestNumber", nil];
	
	NSManagedObject *managedObject = [NSManagedObject managedObjectWithDictionary:dictionary entity:entity managedObjectContext:managedObjectContext bundle:bundle];
	
	STAssertTrue([[managedObject valueForKey:@"uniqueField"] isEqualToString:@"someUniqueValue_45"], nil);
}

@end
