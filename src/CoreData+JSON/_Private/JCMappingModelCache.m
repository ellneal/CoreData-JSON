//
//  JCMappingModelCache.m
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

#import "JCMappingModelCache.h"

@interface JCMappingModelCache (Private)

@property (nonatomic, readonly) NSMutableDictionary *cache;

@end

@implementation JCMappingModelCache

- (JCMappingModel *)mappingModelForEntity:(NSEntityDescription *)entity {
	
	return [[[[self cache] objectForKey:[entity name]] retain] autorelease];
}
- (void)setMappingModel:(JCMappingModel *)mappingModel forEntity:(NSEntityDescription *)entity {
	
	[[self cache] setObject:mappingModel forKey:[entity name]];
}

- (void)clearCache {
	
	[cache_ release];
	cache_ = nil;
}

- (NSMutableDictionary *)cache {
	
	if (cache_ != nil)
		return cache_;
	
	cache_ = [[NSMutableDictionary alloc] init];
	
	return cache_;
}

static JCMappingModelCache *defaultCache_;

+ (JCMappingModelCache *)defaultCache {
	
	if (defaultCache_ != nil)
		return defaultCache_;
	
	defaultCache_ = [[JCMappingModelCache alloc] init];
	
	return defaultCache_;
}

- (void)dealloc {
	
	[self clearCache];
	
	[super dealloc];
}

@end
