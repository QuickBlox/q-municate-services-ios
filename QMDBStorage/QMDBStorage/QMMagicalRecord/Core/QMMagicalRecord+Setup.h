//
//  QMMagicalRecord+Setup.h
//  QMMagical Record
//
//  Created by Saul Mora on 3/7/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import "QMMagicalRecord.h"

@interface QMMagicalRecord (Setup)

+ (void) setupCoreDataStack;
+ (void) setupCoreDataStackWithInMemoryStore;
+ (void) setupAutoMigratingCoreDataStack;

+ (void) setupCoreDataStackWithStoreNamed:(NSString *)storeName;
+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreNamed:(NSString *)storeName;

+ (void) setupCoreDataStackWithStoreAtURL:(NSURL *)storeURL;
+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL;


@end
