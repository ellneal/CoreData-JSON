//
//  JCMappingModel.m
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

#import "JCMappingModel.h"
#import "JCMappingModelCache.h"
#import "ConvenienceCategories.h"

@interface JCMappingModel (Private)

- (void)checkEntityIsNotNil:(NSEntityDescription *)entity;
- (void)checkFilePathIsNotNil:(NSString *)filePath;
- (void)checkUniqueFieldIsNotNil:(NSString *)uniqueField;
- (void)checkEntity:(NSEntityDescription *)entity hasFieldNamed:(NSString *)field;
- (void)checkPropertiesMapIsNotNil:(NSDictionary *)propertiesMap;

- (BOOL)mappedKeyIsExpression:(id)value;
- (id)valueForExpression:(NSString *)expression fromDictionary:(NSDictionary *)dictionary withSuperUniqueFieldValue:(id)superUniqueFieldValue;

@end

@implementation JCMappingModel

@synthesize entity = entity_;
@synthesize propertiesMap = propertiesMap_;
@synthesize uniqueField = uniqueField_;
@synthesize valueTransformers = valueTransformers_;

- (id)initWithEntity:(NSEntityDescription *)entity {
	
	return [self initWithEntity:entity bundle:nil];
}

- (id)initWithEntity:(NSEntityDescription *)entity bundle:(NSBundle *)bundleOrNil {
	
	if ((self = [super init])) {
		
		NSBundle *bundle = (bundleOrNil != nil ? bundleOrNil : [NSBundle mainBundle]);
		
		[self checkEntityIsNotNil:entity];
		entity_ = [entity retain];
		
		NSString *fileName = [entity name];
		NSString *filePath = [bundle pathForResource:fileName ofType:@"jcmap"];
		[self checkFilePathIsNotNil:filePath];
		
		NSDictionary *map = [NSDictionary dictionaryWithContentsOfFile:filePath];
		
		NSEntityDescription *superentity = [entity superentity];
		JCMappingModel *superMap = nil;
		
		if (superentity != nil)
			superMap = [JCMappingModel mappingModelForEntity:superentity bundle:bundleOrNil];
		
		NSString *uniqueField = [map objectForKey:kUniqueFieldMapKey];
		if (uniqueField == nil && superMap != nil)
			uniqueField = [superMap uniqueField];
		[self checkUniqueFieldIsNotNil:uniqueField];
		[self checkEntity:entity hasFieldNamed:uniqueField];
		uniqueField_ = [uniqueField copy];
		
		NSDictionary *propertiesMap = [map objectForKey:kPropertiesMapKey];
		[self checkPropertiesMapIsNotNil:propertiesMap];
		
		NSDictionary *valueTransformers = [map objectForKey:kValueTransformersMapKey];
		
		if (superMap != nil) {
			propertiesMap = [propertiesMap dictionaryByAddingEntriesFromDictionary:superMap.propertiesMap];
			valueTransformers = [valueTransformers dictionaryByAddingEntriesFromDictionary:superMap.valueTransformers];
		}
		
		propertiesMap_ = [propertiesMap retain];
		valueTransformers_ = [valueTransformers retain];
	}
	
	return self;
}

+ (JCMappingModel *)mappingModelForEntity:(NSEntityDescription *)entity {
	
	return [JCMappingModel mappingModelForEntity:entity bundle:nil];
}

+ (JCMappingModel *)mappingModelForEntity:(NSEntityDescription *)entity bundle:(NSBundle *)bundleOrNil {
	
    JCMappingModelCache *cache = [JCMappingModelCache defaultCache];
	JCMappingModel *mappingModel = [cache mappingModelForEntity:entity];
	
	if (mappingModel == nil) {
		
		mappingModel = [[[JCMappingModel alloc] initWithEntity:entity bundle:bundleOrNil] autorelease];
		[cache setMappingModel:mappingModel forEntity:entity];
	}
	
	return mappingModel;
}

- (void)checkEntityIsNotNil:(NSEntityDescription *)entity {
	
	if (entity == nil)
		[NSException raise:@"NilEntityException" format:@"Cannot create mapping model from nil entity."];
}

- (void)checkFilePathIsNotNil:(NSString *)filePath {
	
	if (filePath == nil || [filePath length] == 0)
		[NSException raise:@"NoMappingModelException" format:@"Could not find mapping model for entity with name '%@'.", [self.entity name]];
}
	
- (void)checkUniqueFieldIsNotNil:(NSString *)uniqueField {
	
	if (uniqueField == nil || [uniqueField length] == 0)
		[NSException raise:@"NoUniqueFieldException" format:@"Could not find unique field (key: %@) for entity with name '%@'.", kUniqueFieldMapKey, [self.entity name]];
}

- (void)checkEntity:(NSEntityDescription *)entity hasFieldNamed:(NSString *)field {
	
	if ([[entity propertiesByName] objectForKey:field] == nil)
		[NSException raise:@"FieldNotRecognisedException" format:@"Entity '%@' does not contain property named '%@'.", [entity name], field];
}

- (void)checkPropertiesMapIsNotNil:(NSDictionary *)propertiesMap {
	
	if (propertiesMap == nil || [propertiesMap count] == 0)
		[NSException raise:@"NoPropertiesMapException" format:@"Could not find properties map (key: %@) for entity with name '%@'.", kPropertiesMapKey, [self.entity name]];
}

- (id)transformedValue:(id)value forPropertyName:(NSString *)propertyName {
	
	NSString *valueTransformerName = [self.valueTransformers objectForKey:propertyName];
	
	if (valueTransformerName == nil)
		return value;
	
	NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerInstanceWithClassName:valueTransformerName];
	
	id transformedValue = [valueTransformer transformedValue:value];
	
	return transformedValue;
}

- (id)reverseTransformedValue:(id)value forPropertyName:(NSString *)propertyName {
	
	if (value == [NSNull null])
		return value;
	
	NSString *valueTransformerName = [self.valueTransformers objectForKey:propertyName];
	
	if (valueTransformerName == nil)
		return value;
	
	NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerInstanceWithClassName:valueTransformerName];
	
	if (![[valueTransformer class] allowsReverseTransformation])
		return value;
	
	id reverseTransformedValue = [valueTransformer reverseTransformedValue:value];
	
	return reverseTransformedValue;
}

- (id)valueForMappedPropertyName:(NSString *)mappedPropertyName fromDictionary:(NSDictionary *)dictionary {
	
	return [self valueForMappedPropertyName:mappedPropertyName fromDictionary:dictionary withSuperUniqueFieldValue:nil];
}

- (id)valueForMappedPropertyName:(NSString *)mappedPropertyName fromDictionary:(NSDictionary *)dictionary withSuperUniqueFieldValue:(id)superUniqueFieldValue {
	
	id value = nil;
	
	if ([self mappedKeyIsExpression:mappedPropertyName])
		value = [self valueForExpression:[mappedPropertyName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] fromDictionary:dictionary withSuperUniqueFieldValue:superUniqueFieldValue];
	else
		value = [dictionary objectForKeyPath:mappedPropertyName];
	
	return value;
}

- (id)valueForPropertyName:(NSString *)propertyName fromManagedObject:(NSManagedObject *)managedObject {
	
	NSString *mappedKey = [self.propertiesMap objectForKey:propertyName];
	id value = nil;
	
	if (![self mappedKeyIsExpression:mappedKey]) {
		
		value = [managedObject valueForKey:propertyName];
		
		if (value == nil)
			value = [NSNull null];
	}
	
	return value;
}

- (BOOL)mappedKeyIsExpression:(id)value {
	
	if ([value isKindOfClass:[NSString class]]) {
		
		NSString *cleanedString = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if ([[cleanedString substringToIndex:1] isEqualToString:@"{"]) {
			
			return YES;
		}
	}
	
	return NO;
}

- (id)valueForExpression:(NSString *)expression fromDictionary:(NSDictionary *)dictionary withSuperUniqueFieldValue:(id)superUniqueFieldValue {
	
	//remove curly braces
	NSString *cleanedExpression = [expression substringWithRange:NSMakeRange(1, [expression length] - 2)];
	//remove whitespace
	cleanedExpression = [cleanedExpression stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	NSRange rangeOfFormat = NSMakeRange(2, [cleanedExpression rangeOfString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(2, [cleanedExpression length]-2)].location-2);
	NSRange rangeOfArguments = NSMakeRange(rangeOfFormat.location+rangeOfFormat.length+1, [cleanedExpression length]-(rangeOfFormat.location+rangeOfFormat.length+1));
	
	NSString *formatString = [cleanedExpression substringWithRange:rangeOfFormat];
	NSString *argumentsString = [cleanedExpression substringWithRange:rangeOfArguments];
	argumentsString = [argumentsString stringByRemovingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	argumentsString = [argumentsString substringWithRange:NSMakeRange(1, [argumentsString length]-1)];
	
	NSArray *arguments = [argumentsString componentsSeparatedByString:@","];
	
	if ([arguments count] == 0)
		return formatString;
	
	NSMutableArray *argumentValues = [[NSMutableArray alloc] initWithCapacity:[arguments count]];
	
	for (NSString *mappedKey in arguments) {
        
		if ([mappedKey isEqualToString:@"superUniqueFieldValue"]) {
            
            if (superUniqueFieldValue != nil)
                [argumentValues addObject:superUniqueFieldValue];
            else
                [argumentValues addObject:[NSNull null]];
        }
		else {
            
			[argumentValues addObject:[self valueForMappedPropertyName:mappedKey fromDictionary:dictionary]];
        }
	}
	
	NSString *result = [NSString stringWithFormat:formatString array:argumentValues];
	
	[argumentValues release];
	
	return result;
}

- (void)dealloc {
	
	[entity_ release];
	entity_ = nil;
	
	[propertiesMap_ release];
	propertiesMap_ = nil;
	
	[uniqueField_ release];
	uniqueField_ = nil;
	
	[valueTransformers_ release];
	valueTransformers_ = nil;
	
	[super dealloc];
}

@end
