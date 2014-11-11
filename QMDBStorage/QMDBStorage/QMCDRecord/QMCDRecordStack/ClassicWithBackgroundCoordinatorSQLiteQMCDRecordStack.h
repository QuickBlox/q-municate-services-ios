//
//  DualContextDualCoordinatorQMCDRecordStack.h
//  QMCDRecord
//
//  Created by Saul Mora on 10/14/13.
//  Copyright (c) 2013 QMCD Panda Software LLC. All rights reserved.
//

#import "ClassicSQLiteQMCDRecordStack.h"

@interface ClassicWithBackgroundCoordinatorSQLiteQMCDRecordStack : ClassicSQLiteQMCDRecordStack

@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *backgroundCoordinator;

@end
