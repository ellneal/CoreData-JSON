//
//  NSManagedObjectContext+JSON_Tests.m
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

#import "NSManagedObjectContext+JSON_Tests.h"

#import "NSManagedObjectContext+JSON.h"
#import "NSManagedObjectContext+UnitTesting.h"


@implementation NSManagedObjectContext_JSON_Tests

- (void)setUp {
	
	bundle = [[NSBundle bundleForClass:[self class]] retain];
	managedObjectContext = [[NSManagedObjectContextUnitTesting inMemoryManagedObjectContextFromBundle:bundle] retain];
}

- (void)tearDown {
	
	[bundle release];
	bundle = nil;
	
	[managedObjectContext release];
	managedObjectContext = nil;
}

- (void)testInsertAndFetchTestEntity {
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"testEntity" inManagedObjectContext:managedObjectContext];
	
	NSString *field = @"uniqueField";
	NSString *fieldValue = @"someUniqueValue";
	
	NSManagedObject *aManagedObject = [managedObjectContext insertManagedObjectForEntity:entity withAttribute:field equalTo:fieldValue];
	
	STAssertNotNil(aManagedObject, @"insertManagedObjectForEntity:withAttribute:equalTo: should return a new managed object");
	STAssertEquals([aManagedObject valueForKey:field], fieldValue, nil);
	STAssertTrue([aManagedObject isInserted], nil);
	
	NSManagedObject *theSameManagedObject = [managedObjectContext fetchManagedObjectForEntity:entity withAttribute:field equalTo:fieldValue];
	
	STAssertNotNil(theSameManagedObject, nil);
	STAssertEqualObjects(aManagedObject, theSameManagedObject, nil);
}

@end
