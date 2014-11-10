//
//  QMMagicalRecord+Setup.m
//  QMMagical Record
//
//  Created by Saul Mora on 3/7/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import "QMMagicalRecord+Setup.h"
#import "NSManagedObject+QMMagicalRecord.h"
#import "NSPersistentStoreCoordinator+QMMagicalRecord.h"
#import "NSManagedObjectContext+QMMagicalRecord.h"

@implementation QMMagicalRecord (Setup)

+ (void) setupCoreDataStack
{
    [self setupCoreDataStackWithStoreNamed:[self defaultStoreName]];
}

+ (void) setupAutoMigratingCoreDataStack
{
    [self setupCoreDataStackWithAutoMigratingSqliteStoreNamed:[self defaultStoreName]];
}

+ (void) setupCoreDataStackWithStoreNamed:(NSString *)storeName
{
    if ([NSPersistentStoreCoordinator QM_defaultStoreCoordinator] != nil) return;
    
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator QM_coordinatorWithSqliteStoreNamed:storeName];
    [NSPersistentStoreCoordinator QM_setDefaultStoreCoordinator:coordinator];
	
    [NSManagedObjectContext QM_initializeDefaultContextWithCoordinator:coordinator];
}

+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreNamed:(NSString *)storeName
{
    if ([NSPersistentStoreCoordinator QM_defaultStoreCoordinator] != nil) return;
    
    NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator QM_coordinatorWithAutoMigratingSqliteStoreNamed:storeName];
    [NSPersistentStoreCoordinator QM_setDefaultStoreCoordinator:coordinator];
    
    [NSManagedObjectContext QM_initializeDefaultContextWithCoordinator:coordinator];
}

+ (void) setupCoreDataStackWithStoreAtURL:(NSURL *)storeURL
{
    if ([NSPersistentStoreCoordinator QM_defaultStoreCoordinator] != nil) return;
    
    NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator QM_coordinatorWithSqliteStoreAtURL:storeURL];
    [NSPersistentStoreCoordinator QM_setDefaultStoreCoordinator:coordinator];
    
    [NSManagedObjectContext QM_initializeDefaultContextWithCoordinator:coordinator];
}

+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL
{
    if ([NSPersistentStoreCoordinator QM_defaultStoreCoordinator] != nil) return;
    
    NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator QM_coordinatorWithAutoMigratingSqliteStoreAtURL:storeURL];
    [NSPersistentStoreCoordinator QM_setDefaultStoreCoordinator:coordinator];
    
    [NSManagedObjectContext QM_initializeDefaultContextWithCoordinator:coordinator];
}

+ (void) setupCoreDataStackWithInMemoryStore;
{
    if ([NSPersistentStoreCoordinator QM_defaultStoreCoordinator] != nil) return;
    
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator QM_coordinatorWithInMemoryStore];
	[NSPersistentStoreCoordinator QM_setDefaultStoreCoordinator:coordinator];
	
    [NSManagedObjectContext QM_initializeDefaultContextWithCoordinator:coordinator];
}

@end
