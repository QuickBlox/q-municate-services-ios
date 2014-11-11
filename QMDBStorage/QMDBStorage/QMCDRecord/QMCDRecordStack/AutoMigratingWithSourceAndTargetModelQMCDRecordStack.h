//
//  CustomMigratingQMCDRecordStack.h
//  QMCDRecord
//
//  Created by Saul Mora on 10/11/13.
//  Copyright (c) 2013 QMCD Panda Software LLC. All rights reserved.
//

#import "SQLiteQMCDRecordStack.h"

@interface AutoMigratingWithSourceAndTargetModelQMCDRecordStack : SQLiteQMCDRecordStack

- (instancetype) initWithSourceModel:(NSManagedObjectModel *)sourceModel targetModel:(NSManagedObjectModel *)targetModel storeAtURL:(NSURL *)storeURL;
- (instancetype) initWithSourceModel:(NSManagedObjectModel *)sourceModel targetModel:(NSManagedObjectModel *)targetModel storeAtPath:(NSString *)path;
- (instancetype) initWithSourceModel:(NSManagedObjectModel *)sourceModel targetModel:(NSManagedObjectModel *)targetModel storeNamed:(NSString *)storeName;

@end
