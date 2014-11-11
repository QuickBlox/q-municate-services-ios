//
//  NSPersistentStoreCoordinator+QMCDInMemoryStoreAdditions.h
//  QMCDRecord
//
//  Created by Saul Mora on 9/14/13.
//  Copyright (c) 2013 QMCD Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSPersistentStoreCoordinator (QMCDInMemoryStoreAdditions)

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithInMemoryStore;
+ (NSPersistentStoreCoordinator *) QM_coordinatorWithInMemoryStoreWithModel:(NSManagedObjectModel *)model;
+ (NSPersistentStoreCoordinator *) QM_coordinatorWithInMemoryStoreWithModel:(NSManagedObjectModel *)model withOptions:(NSDictionary *)options;

- (NSPersistentStore *) QM_addInMemoryStore;
- (NSPersistentStore *) QM_addInMemoryStoreWithOptions:(NSDictionary *)options;

@end
