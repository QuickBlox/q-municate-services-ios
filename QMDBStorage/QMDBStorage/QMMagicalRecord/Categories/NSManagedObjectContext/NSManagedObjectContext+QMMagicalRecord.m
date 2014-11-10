//
//  NSManagedObjectContext+QMMagicalRecord.m
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2010 QMMagical Panda Software, LLC All rights reserved.
//

#import "CoreData+QMMagicalRecord.h"
#import "QMMagicalRecordLogging.h"
#import <objc/runtime.h>

static NSString * const QMMagicalRecordContextWorkingName = @"QMMagicalRecordContextWorkingName";

static NSManagedObjectContext *QMMagicalRecordRootSavingContext;
static NSManagedObjectContext *QMMagicalRecordDefaultContext;

static id QMMagicalRecordUbiquitySetupNotificationObserver;

@implementation NSManagedObjectContext (QMMagicalRecord)

#pragma mark - Setup

+ (void) QM_initializeDefaultContextWithCoordinator:(NSPersistentStoreCoordinator *)coordinator;
{
    NSAssert(coordinator, @"Provided coordinator cannot be nil!");
    if (QMMagicalRecordDefaultContext == nil)
    {
        NSManagedObjectContext *rootContext = [self QM_contextWithStoreCoordinator:coordinator];
        [self QM_setRootSavingContext:rootContext];

        NSManagedObjectContext *defaultContext = [self QM_newMainQueueContext];
        [self QM_setDefaultContext:defaultContext];

        [defaultContext setParentContext:rootContext];
    }
}

#pragma mark - Default Contexts

+ (NSManagedObjectContext *) QM_defaultContext
{
    @synchronized(self) {
        NSAssert(QMMagicalRecordDefaultContext != nil, @"Default context is nil! Did you forget to initialize the Core Data Stack?");
        return QMMagicalRecordDefaultContext;
    }
}

+ (NSManagedObjectContext *) QM_rootSavingContext;
{
    return QMMagicalRecordRootSavingContext;
}

#pragma mark - Context Creation

+ (NSManagedObjectContext *) QM_context
{
    return [self QM_contextWithParent:[self QM_rootSavingContext]];
}

+ (NSManagedObjectContext *) QM_contextWithParent:(NSManagedObjectContext *)parentContext
{
    NSManagedObjectContext *context = [self QM_newPrivateQueueContext];
    [context setParentContext:parentContext];
    [context QM_obtainPermanentIDsBeforeSaving];
    return context;
}

+ (NSManagedObjectContext *) QM_contextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	NSManagedObjectContext *context = nil;
    if (coordinator != nil)
	{
        context = [self QM_newPrivateQueueContext];
        [context performBlockAndWait:^{
            [context setPersistentStoreCoordinator:coordinator];
            QMMRLogVerbose(@"Created new context %@ with store coordinator: %@", [context QM_workingName], coordinator);
        }];
    }
    return context;
}

+ (NSManagedObjectContext *) QM_newMainQueueContext
{
    NSManagedObjectContext *context = [[self alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    QMMRLogInfo(@"Created new main queue context: %@", context);
    return context;
}

+ (NSManagedObjectContext *) QM_newPrivateQueueContext
{
    NSManagedObjectContext *context = [[self alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    QMMRLogInfo(@"Created new private queue context: %@", context);
    return context;
}

#pragma mark - Debugging

- (void) QM_setWorkingName:(NSString *)workingName
{
    [[self userInfo] setObject:workingName forKey:QMMagicalRecordContextWorkingName];
}

- (NSString *) QM_workingName
{
    NSString *workingName = [[self userInfo] objectForKey:QMMagicalRecordContextWorkingName];

    if ([workingName length] == 0)
    {
        workingName = @"Untitled Context";
    }

    return workingName;
}

- (NSString *) QM_description
{
    NSString *onMainThread = [NSThread isMainThread] ? @"the main thread" : @"a background thread";

    __block NSString *workingName;

    [self performBlockAndWait:^{
        workingName = [self QM_workingName];
    }];

    return [NSString stringWithFormat:@"<%@ (%p): %@> on %@", NSStringFromClass([self class]), self, workingName, onMainThread];
}

- (NSString *) QM_parentChain
{
    NSMutableString *familyTree = [@"\n" mutableCopy];
    NSManagedObjectContext *currentContext = self;
    do
    {
        [familyTree appendFormat:@"- %@ (%p) %@\n", [currentContext QM_workingName], currentContext, (currentContext == self ? @"(*)" : @"")];
    }
    while ((currentContext = [currentContext parentContext]));

    return [NSString stringWithString:familyTree];
}

#pragma mark - Helpers

+ (void) QM_resetDefaultContext
{
    NSManagedObjectContext *defaultContext = [NSManagedObjectContext QM_defaultContext];
    NSAssert(NSConfinementConcurrencyType == [defaultContext concurrencyType], @"Do not call this method on a confinement context.");

    if ([NSThread isMainThread] == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self QM_resetDefaultContext];
        });

        return;
    }

    [defaultContext reset];
}

- (void) QM_deleteObjects:(id <NSFastEnumeration>)objects
{
    for (NSManagedObject *managedObject in objects)
    {
        [self deleteObject:managedObject];
    }
}

#pragma mark - Notification Handlers

- (void) QM_contextWillSave:(NSNotification *)notification
{
    NSManagedObjectContext *context = [notification object];
    NSSet *insertedObjects = [context insertedObjects];

    if ([insertedObjects count])
    {
        QMMRLogVerbose(@"Context '%@' is about to save: obtaining permanent IDs for %lu new inserted object(s).", [context QM_workingName], (unsigned long)[insertedObjects count]);
        NSError *error = nil;
        BOOL success = [context obtainPermanentIDsForObjects:[insertedObjects allObjects] error:&error];
        if (!success)
        {
            [QMMagicalRecord handleErrors:error];
        }
    }
}

+ (void) rootContextDidSave:(NSNotification *)notification
{
    if ([notification object] != [self QM_rootSavingContext])
    {
        return;
    }

    if ([NSThread isMainThread] == NO)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self rootContextDidSave:notification];
        });

        return;
    }

    [[self QM_defaultContext] mergeChangesFromContextDidSaveNotification:notification];
}

#pragma mark - Private Methods

+ (void) QM_cleanUp
{
    [self QM_setDefaultContext:nil];
    [self QM_setRootSavingContext:nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self QM_clearNonMainThreadContextsCache];
#pragma clang diagnostic pop
}

- (void) QM_obtainPermanentIDsBeforeSaving
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(QM_contextWillSave:)
                                                 name:NSManagedObjectContextWillSaveNotification
                                               object:self];
}

+ (void) QM_setDefaultContext:(NSManagedObjectContext *)moc
{
    if (QMMagicalRecordDefaultContext)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:QMMagicalRecordDefaultContext];
    }

    NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator QM_defaultStoreCoordinator];
    if (QMMagicalRecordUbiquitySetupNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:QMMagicalRecordUbiquitySetupNotificationObserver];
        QMMagicalRecordUbiquitySetupNotificationObserver = nil;
    }

    if ([QMMagicalRecord isICloudEnabled])
    {
        [QMMagicalRecordDefaultContext QM_stopObservingiCloudChangesInCoordinator:coordinator];
    }

    QMMagicalRecordDefaultContext = moc;
    [QMMagicalRecordDefaultContext QM_setWorkingName:@"QMMagicalRecord Default Context"];

    if ((QMMagicalRecordDefaultContext != nil) && ([self QM_rootSavingContext] != nil)) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(rootContextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:[self QM_rootSavingContext]];
    }

    [moc QM_obtainPermanentIDsBeforeSaving];
    if ([QMMagicalRecord isICloudEnabled])
    {
        [QMMagicalRecordDefaultContext QM_observeiCloudChangesInCoordinator:coordinator];
    }
    else
    {
        // If icloud is NOT enabled at the time of this method being called, listen for it to be setup later, and THEN set up observing cloud changes
        QMMagicalRecordUbiquitySetupNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kQMMagicalRecordPSCDidCompleteiCloudSetupNotification
                                                                                            object:nil
                                                                                             queue:[NSOperationQueue mainQueue]
                                                                                        usingBlock:^(NSNotification *note) {
                                                                                            [[NSManagedObjectContext QM_defaultContext] QM_observeiCloudChangesInCoordinator:coordinator];
                                                                                        }];
    }
    QMMRLogInfo(@"Set default context: %@", QMMagicalRecordDefaultContext);
}

+ (void)QM_setRootSavingContext:(NSManagedObjectContext *)context
{
    if (QMMagicalRecordRootSavingContext)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:QMMagicalRecordRootSavingContext];
    }

    QMMagicalRecordRootSavingContext = context;
    
    [context performBlock:^{
        [context QM_obtainPermanentIDsBeforeSaving];
        [QMMagicalRecordRootSavingContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        [QMMagicalRecordRootSavingContext QM_setWorkingName:@"QMMagicalRecord Root Saving Context"];
    }];

    QMMRLogInfo(@"Set root saving context: %@", QMMagicalRecordRootSavingContext);
}

@end

#pragma mark - Deprecated Methods — DO NOT USE
@implementation NSManagedObjectContext (QMMagicalRecordDeprecated)

+ (NSManagedObjectContext *) QM_contextWithoutParent
{
    return [self QM_newPrivateQueueContext];
}

+ (NSManagedObjectContext *) QM_newContext
{
    return [self QM_context];
}

+ (NSManagedObjectContext *) QM_newContextWithParent:(NSManagedObjectContext *)parentContext
{
    return [self QM_contextWithParent:parentContext];
}

+ (NSManagedObjectContext *) QM_newContextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
    return [self QM_contextWithStoreCoordinator:coordinator];
}

@end
