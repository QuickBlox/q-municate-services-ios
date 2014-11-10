//
//  QMMagicalRecord+Options.m
//  QMMagical Record
//
//  Created by Saul Mora on 3/6/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import "QMMagicalRecord+Options.h"

static QMMagicalRecordLoggingLevel kQMMagicalRecordLoggingLevel = QMMagicalRecordLoggingLevelVerbose;
static BOOL kQMMagicalRecordShouldAutoCreateManagedObjectModel = NO;
static BOOL kQMMagicalRecordShouldAutoCreateDefaultPersistentStoreCoordinator = NO;
static BOOL kQMMagicalRecordShouldDeleteStoreOnModelMismatch = NO;

@implementation QMMagicalRecord (Options)

#pragma mark - Configuration Options

+ (BOOL) shouldAutoCreateManagedObjectModel;
{
    return kQMMagicalRecordShouldAutoCreateManagedObjectModel;
}

+ (void) setShouldAutoCreateManagedObjectModel:(BOOL)autoCreate;
{
    kQMMagicalRecordShouldAutoCreateManagedObjectModel = autoCreate;
}

+ (BOOL) shouldAutoCreateDefaultPersistentStoreCoordinator;
{
    return kQMMagicalRecordShouldAutoCreateDefaultPersistentStoreCoordinator;
}

+ (void) setShouldAutoCreateDefaultPersistentStoreCoordinator:(BOOL)autoCreate;
{
    kQMMagicalRecordShouldAutoCreateDefaultPersistentStoreCoordinator = autoCreate;
}

+ (BOOL) shouldDeleteStoreOnModelMismatch;
{
    return kQMMagicalRecordShouldDeleteStoreOnModelMismatch;
}

+ (void) setShouldDeleteStoreOnModelMismatch:(BOOL)shouldDelete;
{
    kQMMagicalRecordShouldDeleteStoreOnModelMismatch = shouldDelete;
}

+ (QMMagicalRecordLoggingLevel) loggingLevel;
{
    return kQMMagicalRecordLoggingLevel;
}

+ (void) setLoggingLevel:(QMMagicalRecordLoggingLevel)level;
{
    kQMMagicalRecordLoggingLevel = level;
}

@end
