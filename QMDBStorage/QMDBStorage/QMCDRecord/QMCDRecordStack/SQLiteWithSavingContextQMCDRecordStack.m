//
//  ThreadedSQLiteQMCDRecordStack.m
//  QMCDRecord
//
//  Created by Saul Mora on 9/15/13.
//  Copyright (c) 2013 QMCD Panda Software LLC. All rights reserved.
//

#import "QMCDRecordStack+Private.h"
#import "SQLiteWithSavingContextQMCDRecordStack.h"
#import "NSManagedObjectContext+QMCDObserving.h"
#import "NSManagedObjectContext+QMCDRecord.h"

@interface SQLiteWithSavingContextQMCDRecordStack ()

@property (nonatomic, strong, readwrite) NSManagedObjectContext *savingContext;

@end


@implementation SQLiteWithSavingContextQMCDRecordStack

@synthesize context = _context;

- (void)dealloc;
{
    [_context QM_stopObservingContextDidSave:_savingContext];
}

- (NSManagedObjectContext *) context;
{
    if (_savingContext == nil)
    {
        _savingContext = [NSManagedObjectContext QM_privateQueueContext];
        [_savingContext setPersistentStoreCoordinator:[self coordinator]];
    }

    if (_context == nil)
    {
        _context = [NSManagedObjectContext QM_mainQueueContext];
        [_context setPersistentStoreCoordinator:[self coordinator]];

        [_context QM_observeContextDidSave:_savingContext];
    }

    return _context;
}

- (NSManagedObjectContext *) newConfinementContext;
{
    NSManagedObjectContext *context = [super createConfinementContext];
    [context setParentContext:[self savingContext]];
    return context;
}

@end
