//
//  JCMappingModel.m
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

#import "JCMappingModel.h"
#import "JCMappingModelCache.h"
#import "ConvenienceCategories.h"

@interface JCMappingModel (Private)

- (void)checkEntityIsNotNil:(NSEntityDescription *)entity;
- (void)checkFilePathIsNotNil:(NSString *)filePath;
- (void)checkUniqueFieldIsNotNil:(NSString *)uniqueField;
- (void)checkEntity:(NSEntityDescription *)entity hasFieldNamed:(NSString *)field;
- (void)checkPropertiesMapIsNotNil:(NSDictionary *)propertiesMap;

- (BOOL)valueIsExpression:(id)value;
- (id)valueForExpression:(NSString *)expression fromDictionary:(NSDictionary *)dictionary;

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
	
	if (self = [super init]) {
		
		NSBundle *bundle = (bundleOrNil != nil ? bundleOrNil : [NSBundle mainBundle]);
		
		[self checkEntityIsNotNil:entity];
		entity_ = [entity retain];
		
		NSString *fileName = [entity name];
		NSString *filePath = [bundle pathForResource:fileName ofType:@"jcmap"];
		[self checkFilePathIsNotNil:filePath];
		
		NSDictionary *map = [NSDictionary dictionaryWithContentsOfFile:filePath];
		
		NSString *uniqueField = [map objectForKey:kUniqueFieldMapKey];
		[self checkUniqueFieldIsNotNil:uniqueField];
		[self checkEntity:entity hasFieldNamed:uniqueField];
		uniqueField_ = [uniqueField copy];
		
		NSDictionary *propertiesMap = [map objectForKey:kPropertiesMapKey];
		[self checkPropertiesMapIsNotNil:propertiesMap];
		propertiesMap_ = [propertiesMap retain];
		
		NSDictionary *valueTransformers = [map objectForKey:kValueTransformersMapKey];
		valueTransformers_ = [valueTransformers retain];
	}
	
	return self;
}

+ (JCMappingModel *)mappingModelWithEntity:(NSEntityDescription *)entity {
	
	return [JCMappingModel mappingModelWithEntity:entity bundle:nil];
}

+ (JCMappingModel *)mappingModelWithEntity:(NSEntityDescription *)entity bundle:(NSBundle *)bundleOrNil {
	
	JCMappingModel *mappingModel = [[JCMappingModelCache defaultCache] mappingModelForEntity:entity];
	
	if (mappingModel == nil) {
		
		mappingModel = [[[JCMappingModel alloc] initWithEntity:entity bundle:bundleOrNil] autorelease];
		[[JCMappingModelCache defaultCache] setMappingModel:mappingModel forEntity:entity];
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

- (id)valueForMappedKey:(NSString *)mappedKey fromDictionary:(NSDictionary *)dictionary {
	
	id value = nil;
	
	if ([self valueIsExpression:mappedKey])
		value = [self valueForExpression:[mappedKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] fromDictionary:dictionary];
	else
		value = [dictionary nilIfNSNullObjectForKey:mappedKey];
	
	return value;
}

- (BOOL)valueIsExpression:(id)value {
	
	if ([value isKindOfClass:[NSString class]]) {
		
		NSString *cleanedString = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if ([[cleanedString substringToIndex:1] isEqualToString:@"{"]) {
			
			return YES;
		}
	}
	
	return NO;
}

- (id)valueForExpression:(NSString *)expression fromDictionary:(NSDictionary *)dictionary {
	
	//remove curly braces
	NSString *cleanedExpression = [expression substringWithRange:NSMakeRange(1, [expression length] - 2)];
	//remove whitespace
	cleanedExpression = [cleanedExpression stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	NSRange rangeOfFormat = NSMakeRange(2, [cleanedExpression rangeOfString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(2, [cleanedExpression length]-2)].location-2);
	NSRange rangeOfArguments = NSMakeRange(rangeOfFormat.location+rangeOfFormat.length+1, [cleanedExpression length]-(rangeOfFormat.location+rangeOfFormat.length+1));
	
	NSString *formatString = [cleanedExpression substringWithRange:rangeOfFormat];
	NSString *argumentsString = [cleanedExpression substringWithRange:rangeOfArguments];
	
	NSArray *arguments = [argumentsString componentsSeparatedByString:@","];
	NSMutableArray *cleanedArguments = [[[NSMutableArray alloc] initWithCapacity:[arguments count]] autorelease];
	
	for (NSString *arg in arguments) {
		if (![NSString stringIsNilOrEmpty:arg])
			[cleanedArguments addObject:[arg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	}
	
	if ([cleanedArguments count] == 0)
		return formatString;
	
	NSMutableArray *argumentValues = [[NSMutableArray alloc] initWithCapacity:[cleanedArguments count]];
	
	for (NSString *mappedKey in cleanedArguments)
		[argumentValues addObject:[self valueForMappedKey:mappedKey fromDictionary:dictionary]];
	
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
