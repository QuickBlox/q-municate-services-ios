//
//  InMemoryQMCDRecordStack.m
//  QMCDRecord
//
//  Created by Saul Mora on 9/14/13.
//  Copyright (c) 2013 QMCD Panda Software LLC. All rights reserved.
//

#import "QMCDRecordStack+Private.h"
#import "InMemoryQMCDRecordStack.h"
#import "NSPersistentStoreCoordinator+QMCDInMemoryStoreAdditions.h"

@implementation InMemoryQMCDRecordStack

- (NSManagedObjectContext *) newConfinementContext;
{
    NSManagedObjectContext *context = [super createConfinementContext];
    [context setParentContext:[self context]];
    return context;
}

- (NSPersistentStoreCoordinator *) createCoordinatorWithOptions:(NSDictionary *)options
{
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self model]];

    [coordinator QM_addInMemoryStoreWithOptions:options];

    return coordinator;
}

@end
