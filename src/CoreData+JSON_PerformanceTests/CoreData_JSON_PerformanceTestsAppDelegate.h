//
//  CoreData_JSON_PerformanceTestsAppDelegate.h
//  CoreData+JSON_PerformanceTests
//
//  Created by Elliot Neal on 02/10/2011.
//  Copyright 2011 emdentec. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CoreData_JSON_PerformanceTestsAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (void)generateJSONWithObjectCount:(NSUInteger)objectCount;
- (NSDictionary *)generateObject1;
- (NSDictionary *)generateObject2;

@end
