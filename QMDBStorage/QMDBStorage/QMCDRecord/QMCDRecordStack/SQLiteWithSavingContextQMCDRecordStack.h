//
//  ThreadedSQLiteQMCDRecordStack.h
//  QMCDRecord
//
//  Created by Saul Mora on 9/15/13.
//  Copyright (c) 2013 QMCD Panda Software LLC. All rights reserved.
//

#import "SQLiteQMCDRecordStack.h"

@interface SQLiteWithSavingContextQMCDRecordStack : SQLiteQMCDRecordStack

@property (nonatomic, strong, readonly) NSManagedObjectContext *savingContext;

@end
