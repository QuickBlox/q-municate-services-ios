//
//  QMCDRecord+Setup.h
//  QMCD Record
//
//  Created by Saul Mora on 3/7/12.
//  Copyright (c) 2012 QMCD Panda Software LLC. All rights reserved.
//

#import "QMCDRecord.h"

@class QMCDRecordStack;

@interface QMCDRecord (Setup)

+ (QMCDRecordStack *) setupSQLiteStack;
+ (QMCDRecordStack *) setupSQLiteStackWithStoreAtURL:(NSURL *)url;
+ (QMCDRecordStack *) setupSQLiteStackWithStoreNamed:(NSString *)storeName;

+ (QMCDRecordStack *) setupAutoMigratingStack;
+ (QMCDRecordStack *) setupAutoMigratingStackWithSQLiteStoreNamed:(NSString *)storeName;
+ (QMCDRecordStack *) setupAutoMigratingStackWithSQLiteStoreAtURL:(NSURL *)url;

+ (QMCDRecordStack *) setupManuallyMigratingStack;
+ (QMCDRecordStack *) setupManuallyMigratingStackWithSQLiteStoreNamed:(NSString *)storeName;
+ (QMCDRecordStack *) setupManuallyMigratingStackWithSQLiteStoreAtURL:(NSURL *)url;

+ (QMCDRecordStack *) setupClassicStack;
+ (QMCDRecordStack *) setupClassicStackWithSQLiteStoreNamed:(NSString *)storeName;
+ (QMCDRecordStack *) setupClassicStackWithSQLiteStoreAtURL:(NSURL *)storeURL;

+ (QMCDRecordStack *) setupiCloudStackWithLocalStoreNamed:(NSString *)localStore;

+ (QMCDRecordStack *) setupStackWithInMemoryStore;

@end
