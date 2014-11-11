//
//  ManuallyMigratingQMCDRecordStack.m
//  QMCDRecord
//
//  Created by Saul Mora on 9/14/13.
//  Copyright (c) 2013 QMCD Panda Software LLC. All rights reserved.
//

#import "QMCDRecordStack+Private.h"
#import "ManuallyMigratingQMCDRecordStack.h"
#import "NSPersistentStoreCoordinator+QMCDManualMigrations.h"

@implementation ManuallyMigratingQMCDRecordStack

- (NSPersistentStoreCoordinator *) createCoordinator;
{
    NSPersistentStoreCoordinator
    *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self model]];
    [coordinator QM_addManuallyMigratingSqliteStoreAtURL:self.storeURL];

    return coordinator;
}

@end
