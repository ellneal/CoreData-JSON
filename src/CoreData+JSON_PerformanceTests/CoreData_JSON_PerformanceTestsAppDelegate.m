//
//  CoreData_JSON_PerformanceTestsAppDelegate.m
//  CoreData+JSON_PerformanceTests
//
//  Created by Elliot Neal on 02/10/2011.
//  Copyright 2011 emdentec. All rights reserved.
//

#import "CoreData_JSON_PerformanceTestsAppDelegate.h"

#import "JSONKit.h"
#import "CoreData+JSON.h"


@implementation CoreData_JSON_PerformanceTestsAppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self.managedObjectContext setUndoManager:nil];
    
    NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
    NSArray *jsonObjects = [jsonData objectFromJSONData];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entity1" inManagedObjectContext:self.managedObjectContext];
    
    NSDate *timerStart;
    NSDate *timerEnd;
    NSTimeInterval timerInterval;
    
    timerStart = [NSDate date];
    
    JCImporter *importer = [[JCImporter alloc] initWithManagedObjectContext:self.managedObjectContext bundle:nil];
    [importer managedObjectsFromArray:jsonObjects forEntity:entity withBatchSize:50];
    [importer release];
    
    [self saveContext];
    
    timerEnd = [NSDate date];
    timerInterval = [timerEnd timeIntervalSinceDate:timerStart];
    NSLog(@"Imported %d objects after %f seconds", [jsonObjects count], timerInterval);
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)generateJSONWithObjectCount:(NSUInteger)objectCount {
    
    NSURL *jsonURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"data.json"];
    
    NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:objectCount];
    
    for (int i = 0; i < objectCount; i++) {
        
        NSDictionary *object = [self generateObject1];
        
        [objects addObject:object];
    }
    
    NSData *jsonData = [objects JSONDataWithOptions:JKSerializeOptionPretty error:nil];
    [objects release];
    
    [jsonData writeToURL:jsonURL atomically:NO];
}

- (NSDictionary *)generateObject1 {
    
    int field1 = arc4random();
    int field2 = arc4random();
    
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
    NSString *uuidNSString = [(NSString *)uuidString autorelease];
    CFRelease(uuid);
    
    NSNumber *field1Num = [NSNumber numberWithInt:field1];
    NSNumber *field2Num = [NSNumber numberWithInt:field2];
    
    int numberOfRelationshipObjectsToMake = arc4random() % 6;
    NSMutableArray *relationshipObjects = [NSMutableArray arrayWithCapacity:numberOfRelationshipObjectsToMake];
    for (int i = 0; i < numberOfRelationshipObjectsToMake; i++)
        [relationshipObjects addObject:[self generateObject2]];
    
    NSDictionary *object = [[[NSDictionary alloc] initWithObjectsAndKeys:uuidNSString, @"id", field1Num, @"field1", field2Num, @"field2", relationshipObjects, @"relationship", nil] autorelease];
    
    return object;
}

- (NSDictionary *)generateObject2 {
    
    int field1 = arc4random();
    int field2 = arc4random();
    int field3 = arc4random();
    
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
    NSString *uuidNSString = [(NSString *)uuidString autorelease];
    CFRelease(uuid);
    
    NSNumber *field1Num = [NSNumber numberWithInt:field1];
    NSNumber *field2Num = [NSNumber numberWithInt:field2];
    NSNumber *field3Num = [NSNumber numberWithInt:field3];
    
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:uuidNSString, @"id", field1Num, @"field1", field2Num, @"field2", field3Num, @"field3", nil];
    
    return object;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
    [self saveContext];
}

- (void)dealloc {
    
    [_window release];
    [__managedObjectContext release];
    [__managedObjectModel release];
    [__persistentStoreCoordinator release];
    
    [super dealloc];
}

- (void)saveContext {
    
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    
    if (managedObjectContext != nil) {
        
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}


#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
    
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return __managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CoreData_JSON_PerformanceTests" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    
    return __managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CoreData_JSON_PerformanceTests.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}


#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory {
    
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
