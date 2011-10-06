//
//  JCMManagedCache.h
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class JCProxyObject;

@interface JCProxyObjectCache : NSObject <NSFastEnumeration>


@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSEntityDescription *entity;


- (id)initWithEntity:(NSEntityDescription *)entity managedObjectContext:(NSManagedObjectContext *)managedObjectContext bundle:(NSBundle *)bundleOrNil;


- (JCProxyObject *)proxyObjectForUniqueFieldValue:(id)uniqueFieldValue;
- (void)addProxyObject:(JCProxyObject *)managedObject;
- (void)addProxyObjectsFromJSONObjects:(NSArray *)jsonObjects superUniqueFieldValue:(id)superUniqueFieldValue;
- (void)fetchManagedObjects;

- (id)uniqueFieldValueForJSONObject:(id)jsonObject superUniqueFieldValue:(id)superUniqueFieldValue;


- (NSDictionary *)generateRelationshipCaches;


- (NSUInteger)count;
- (JCProxyObject *)proxyObjectAtIndex:(NSUInteger)index;

- (JCProxyObjectCache *)subcacheWithRange:(NSRange)range;

- (NSArray *)uniqueFieldValues;
- (NSArray *)jsonObjects;
- (NSArray *)managedObjects;

@end
