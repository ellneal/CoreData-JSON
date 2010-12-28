//
//  JCMappingModelTests.m
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

#import "JCMappingModelTests.h"
#import "JCMappingModel.h"
#import "FauxEntityDescription.h"

@implementation JCMappingModelTests

- (void)setUp {
	
	bundle = [[NSBundle bundleForClass:[self class]] retain];
}

- (void)tearDown {
	
	[bundle release];
	bundle = nil;
}

- (void)testNilEntity {
	
	STAssertThrowsSpecificNamed([JCMappingModel mappingModelWithEntity:nil bundle:bundle], NSException, @"NilEntityException", @"Creating JCMappingModel with nil entity should throw Exception.");
}

- (void)testNilFilePath {
	
	NSEntityDescription *entity = [FauxEntityDescription entityDescriptionWithName:@"AnEntity"];
	
	STAssertThrowsSpecificNamed([JCMappingModel mappingModelWithEntity:entity bundle:bundle], NSException, @"NoMappingModelException", @"Creating JCMappingModel with entity with no corresponding map file should throw Exception.");
}

- (void)testNilUniqueField {
	
	NSEntityDescription *entity = [FauxEntityDescription entityDescriptionWithName:@"TestMissingUniqueField"];
	
	STAssertThrowsSpecificNamed([JCMappingModel mappingModelWithEntity:entity bundle:bundle], NSException, @"NoUniqueFieldException", @"Creating JCMappingModel with mapping file with no UniqueField key should throw Exception.");
}

- (void)testBlankUniqueField {
	
	NSEntityDescription *entity = [FauxEntityDescription entityDescriptionWithName:@"TestBlankUniqueField"];
	
	STAssertThrowsSpecificNamed([JCMappingModel mappingModelWithEntity:entity bundle:bundle], NSException, @"NoUniqueFieldException", @"Creating JCMappingModel with mapping file with blank value for UniqueField key should throw Exception.");
}

- (void)testNilPropertiesMap {
	
	NSEntityDescription *entity = [FauxEntityDescription entityDescriptionWithName:@"TestNilPropertiesMap"];
	
	STAssertThrowsSpecificNamed([JCMappingModel mappingModelWithEntity:entity bundle:bundle], NSException, @"NoPropertiesMapException", @"Creating JCMappingModel with mapping file with no PropertiesMap key should throw Exception.");
}

- (void)testBlankPropertiesMap {
	
	NSEntityDescription *entity = [FauxEntityDescription entityDescriptionWithName:@"TestBlankPropertiesMap"];
	
	STAssertThrowsSpecificNamed([JCMappingModel mappingModelWithEntity:entity bundle:bundle], NSException, @"NoPropertiesMapException", @"Creating JCMappingModel with mapping file with blank value for PropertiesMap key should throw Exception.");
}

- (void)testIncorrectUniqueField {
	
	NSEntityDescription *entity = [FauxEntityDescription entityDescriptionWithName:@"TestIncorrectUniqueField"];
	
	STAssertThrowsSpecificNamed([JCMappingModel mappingModelWithEntity:entity bundle:bundle], NSException, @"FieldNotRecognisedException", @"");
}

- (void)testValidMappingModel {
	
	NSEntityDescription *entity = [FauxEntityDescription entityDescriptionWithName:@"TestValidMappingModel"];
	
	JCMappingModel *model = nil;
	
	STAssertNoThrow((model = [JCMappingModel mappingModelWithEntity:entity bundle:bundle]), @"Creating JCMappingModel with valid mapping file should not throw Exception.");
	STAssertNotNil(model, @"JCMappingModel should not be nil after creation with valid mapping model.");
}

- (void)testEntityDescriptionWithSuperEntity {
	
	NSEntityDescription *entity = [FauxEntityDescription entityDescriptionWithName:@"TestSubEntity" superEntity:[FauxEntityDescription entityDescriptionWithName:@"TestSuperEntity"]];
	
	JCMappingModel *model = nil;
	
	STAssertNoThrow((model = [JCMappingModel mappingModelWithEntity:entity bundle:bundle]), @"Creating JCMappingModel with valid mapping file should not throw Exception.");
	STAssertNotNil(model, @"JCMappingModel should not be nil after creation with valid mapping model.");
	STAssertNotNil([model.propertiesMap objectForKey:@"testSuperAttribute"], nil);
	STAssertNotNil([model.propertiesMap objectForKey:@"testSubAttribute"], nil);
}

@end
