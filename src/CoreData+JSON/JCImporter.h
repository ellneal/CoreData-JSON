//
//  JCImporter.h
//  CoreData+JSON
//
//  Created by Elliot Neal on 02/10/2011.
//  Copyright 2011 emdentec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface JCImporter : NSObject


- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext bundle:(NSBundle *)bundleOrNil;

//  batchSize will be used while importing the root objects, and objects in any to-many relationship
//  batchSize 0 means do not batch
- (NSArray *)managedObjectsFromJSONData:(NSData *)jsonData forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize;
- (NSArray *)managedObjectsFromJSONString:(NSString *)jsonString forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize;
- (NSArray *)managedObjectsFromArray:(NSArray *)jsonObjects forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize;
- (id)managedObjectFromDictionary:(NSDictionary *)jsonObject forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize;

@end
