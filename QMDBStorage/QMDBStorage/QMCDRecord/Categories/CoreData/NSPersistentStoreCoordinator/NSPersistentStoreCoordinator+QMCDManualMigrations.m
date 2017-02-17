//
//  NSPersistentStoreCoordinator+QMCDManualMigrations.m
//  QMCDRecord
//
//  Created by Injoit on 9/14/13.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//

#import "NSPersistentStoreCoordinator+QMCDManualMigrations.h"
#import "NSDictionary+QMCDRecordAdditions.h"
#import "NSPersistentStoreCoordinator+QMCDRecord.h"
#import "QMCDRecordStack.h"


@implementation NSPersistentStoreCoordinator (QMCDManualMigrations)

- (NSPersistentStore *)QM_addManuallyMigratingSqliteStoreNamed:(NSString *)storeFileName;
{
    NSDictionary *options = [NSDictionary QM_manualMigrationOptions];
    return [self QM_addSqliteStoreNamed:storeFileName withOptions:options];
}

- (NSPersistentStore *)QM_addManuallyMigratingSqliteStoreAtURL:(NSURL *)url;
{
    NSDictionary *options = [NSDictionary QM_manualMigrationOptions];
    return [self QM_addSqliteStoreAtURL:url withOptions:options];
}

@end
