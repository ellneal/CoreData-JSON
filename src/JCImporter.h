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


- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext bundle:(NSBundle *)bundle;

//  batchSize will be used while importing the root objects, and objects in any to-many relationship
- (NSArray *)importObjectsFromJSONData:(NSData *)jsonData forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize;
- (NSArray *)importObjectsFromJSONString:(NSString *)jsonString forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize;
- (NSArray *)importObjectsFromArray:(NSArray *)jsonObjects forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize;
- (id)importObjectFromDictionary:(NSDictionary *)jsonObject forEntity:(NSEntityDescription *)entity withBatchSize:(NSUInteger)batchSize;

@end
