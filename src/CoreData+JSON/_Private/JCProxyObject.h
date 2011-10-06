//
//  JCManagedObject.h
//  CoreData+JSON
//
//  Created by Elliot Neal on 05/10/2011.
//  Copyright 2011 emdentec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class JCMappingModel;
@class JCProxyObjectCache;

@interface JCProxyObject : NSObject

@property (nonatomic, readonly) NSEntityDescription *entity;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, readonly) id uniqueFieldValue;
@property (nonatomic, readonly) id superUniqueFieldValue;

@property (nonatomic, readonly) id jsonObject;
@property (nonatomic, retain) NSManagedObject *managedObject;


- (id)initWithEntity:(NSEntityDescription *)entity inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext uniqueFieldValue:(id)uniqueFieldValue superUniqueFieldValue:(id)superUniqueFieldValue jsonObject:(id)jsonObject bundle:(NSBundle *)bundleOrNil;

- (void)generateManagedObject;

- (void)updateAttributes;
- (void)updateRelationship:(NSString *)relationshipName fromManagedObjectCache:(JCProxyObjectCache *)managedObjectCache;
- (void)updateInverseRelationships;

- (void)addManagedObject:(NSManagedObject *)managedObject forInverseRelationship:(NSString *)relationshipName;

@end
