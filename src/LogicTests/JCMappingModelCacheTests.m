//
//  JCMappingModelCacheTests.m
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

#import "JCMappingModelCacheTests.h"
#import "JCMappingModel.h"
#import "JCMappingModelCache.h"
#import "FauxEntityDescription.h"

@implementation JCMappingModelCacheTests

- (void)setUp {
	
	entity = [[FauxEntityDescription entityDescriptionWithName:@"TestValidMappingModel"] retain];
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	
	mappingModel = [[JCMappingModel mappingModelWithEntity:entity bundle:bundle] retain];
}

- (void)tearDown {
	
	[entity release];
	entity = nil;
	
	[mappingModel release];
	mappingModel = nil;
}

- (void)testObjectCaching {
	
	STAssertEqualObjects(mappingModel, [[JCMappingModelCache defaultCache] mappingModelForEntity:entity], @"Mapping model cache should store mapping model after using mappingModelWithEntity:");
}

- (void)testClearingCache {
	
	[[JCMappingModelCache defaultCache] clearCache];
	
	STAssertNil([[JCMappingModelCache defaultCache] mappingModelForEntity:entity], @"Mapping model cache should clear all mapping models after using clearCache");
}

@end
