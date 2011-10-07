//
//  NSManagedObjectContext+JSON.m
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

#import "NSManagedObjectContext+JSON.h"
#import "ConvenienceCategories.h"


@implementation NSManagedObjectContext (JSON)

- (id)fetchManagedObjectForEntity:(NSEntityDescription *)entity withAttribute:(NSString *)attribute equalTo:(id)value {
	
	NSAttributeDescription *attributeDescription = [[entity attributesByName] objectForKey:attribute];
	NSPredicate *predicate = nil;
	
	NSAttributeType attributeType = [attributeDescription attributeType];
	
	if (NSAttributeTypeIsString(attributeType)) {
		
		predicate = [NSPredicate predicateWithFormat:@"%K == %@", attribute, value];
	}
	else if (NSAttributeTypeIsInteger(attributeType)) {
		
		predicate = [NSPredicate predicateWithFormat:@"%K == %d", attribute, [value integerValue]];
	}
	
	return [self firstObjectFromResultsFromFetchForEntity:entity predicate:predicate];
}

- (id)insertManagedObjectForEntity:(NSEntityDescription *)entity withAttribute:(NSString *)attribute equalTo:(id)value {
	
	NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:self];
	
	[newObject setValue:value forKey:attribute];
	
	return newObject;
}

- (id)fetchOrInsertManagedObjectForEntity:(NSEntityDescription *)entity withAttribute:(NSString *)attribute equalTo:(id)value {
	
	id managedObject = [self fetchManagedObjectForEntity:entity withAttribute:attribute equalTo:value];
	
	if (managedObject == nil)
		managedObject = [self insertManagedObjectForEntity:entity withAttribute:attribute equalTo:value];
	
	return managedObject;
}


- (id)firstObjectFromResultsFromFetchForEntity:(NSEntityDescription *)entity {
	
	return [self firstObjectFromResultsFromFetchForEntity:entity predicate:nil];
}

- (id)firstObjectFromResultsFromFetchForEntity:(NSEntityDescription *)entity predicate:(NSPredicate *)predicate {
	
	return [self firstObjectFromResultsFromFetchForEntity:entity predicate:predicate sortDescriptors:nil];
}

- (id)firstObjectFromResultsFromFetchForEntity:(NSEntityDescription *)entity predicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors {
	
	NSArray *results = [self resultsFromFetchForEntity:entity predicate:predicate sortDescriptors:sortDescriptors];
	
	if ([results count] == 0)
		return nil;
	
	return [results objectAtIndex:0];
}

- (NSArray *)resultsFromFetchForEntity:(NSEntityDescription *)entity {
	
	return [self resultsFromFetchForEntity:entity predicate:nil];
}

- (NSArray *)resultsFromFetchForEntity:(NSEntityDescription *)entity predicate:(NSPredicate *)predicate {
	
	return [self resultsFromFetchForEntity:entity predicate:predicate sortDescriptors:nil];
}

- (NSArray *)resultsFromFetchForEntity:(NSEntityDescription *)entity predicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors {
	
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntity:entity predicate:predicate sortDescriptors:sortDescriptors];
	
	return [self executeFetchRequest:fetchRequest error:nil];
}

@end
