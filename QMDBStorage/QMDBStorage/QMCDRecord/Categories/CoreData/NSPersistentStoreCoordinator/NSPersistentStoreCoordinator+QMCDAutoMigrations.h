//
//  NSPersistentStoreCoordinator+QMCDAutoMigrations.h
//  QMCDRecord
//
//  Created by Saul Mora on 9/14/13.
//  Copyright (c) 2013 QMCD Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSPersistentStoreCoordinator (QMCDAutoMigrations)

- (NSPersistentStore *) QM_addAutoMigratingSqliteStoreNamed:(NSString *)storeFileName;
- (NSPersistentStore *) QM_addAutoMigratingSqliteStoreNamed:(NSString *)storeFileName withOptions:(NSDictionary *)options;

- (NSPersistentStore *) QM_addAutoMigratingSqliteStoreAtURL:(NSURL *)url;
- (NSPersistentStore *) QM_addAutoMigratingSqliteStoreAtURL:(NSURL *)url withOptions:(NSDictionary *)options;

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithAutoMigratingSqliteStoreNamed:(NSString *)storeFileName;
+ (NSPersistentStoreCoordinator *) QM_coordinatorWithAutoMigratingSqliteStoreAtURL:(NSURL *)url;

@end
