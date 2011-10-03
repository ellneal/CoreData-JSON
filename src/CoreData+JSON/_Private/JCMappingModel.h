//
//  JCMappingModel.h
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define kUniqueFieldMapKey @"UniqueField"
#define kPropertiesMapKey @"PropertiesMap"
#define kValueTransformersMapKey @"ValueTransformers"

@interface JCMappingModel : NSObject {

	NSEntityDescription *entity_;
	
	NSDictionary *propertiesMap_;
	NSString *uniqueField_;
	NSDictionary *valueTransformers_;
}

- (id)initWithEntity:(NSEntityDescription *)entity;
- (id)initWithEntity:(NSEntityDescription *)entity bundle:(NSBundle *)bundleOrNil;
+ (JCMappingModel *)mappingModelWithEntity:(NSEntityDescription *)entity;
+ (JCMappingModel *)mappingModelWithEntity:(NSEntityDescription *)entity;
+ (JCMappingModel *)mappingModelWithEntity:(NSEntityDescription *)entity bundle:(NSBundle *)bundleOrNil;

- (id)transformedValue:(id)value forPropertyName:(NSString *)propertyName;
- (id)reverseTransformedValue:(id)value forPropertyName:(NSString *)propertyName;
- (id)valueForMappedPropertyName:(NSString *)mappedPropertyName fromDictionary:(NSDictionary *)dictionary;
- (id)valueForMappedPropertyName:(NSString *)mappedPropertyName fromDictionary:(NSDictionary *)dictionary withSuperUniqueFieldValue:(id)superUniqueFieldValue;
- (id)valueForPropertyName:(NSString *)propertyName fromManagedObject:(NSManagedObject *)managedObject;

@property (nonatomic, readonly) NSEntityDescription *entity;
@property (nonatomic, readonly) NSDictionary *propertiesMap;
@property (nonatomic, readonly) NSString *uniqueField;
@property (nonatomic, readonly) NSDictionary *valueTransformers;

@end
