//
//  QMMagicalRecord+Actions.m
//
//  Created by Saul Mora on 2/24/11.
//  Copyright 2011 QMMagical Panda Software. All rights reserved.
//

#import "CoreData+QMMagicalRecord.h"
#import "NSManagedObjectContext+QMMagicalRecord.h"


@implementation QMMagicalRecord (Actions)

#pragma mark - Asynchronous saving

+ (void) saveWithBlock:(void(^)(NSManagedObjectContext *localContext))block;
{
    [self saveWithBlock:block completion:nil];
}

+ (void) saveWithBlock:(void(^)(NSManagedObjectContext *localContext))block completion:(QMSaveCompletionHandler)completion;
{
    NSManagedObjectContext *savingContext  = [NSManagedObjectContext QM_rootSavingContext];
    NSManagedObjectContext *localContext = [NSManagedObjectContext QM_contextWithParent:savingContext];

    [localContext performBlock:^{
        [localContext QM_setWorkingName:NSStringFromSelector(_cmd)];

        if (block) {
            block(localContext);
        }

        [localContext QM_saveWithOptions:QMSaveParentContexts completion:completion];
    }];
}

#pragma mark - Synchronous saving

+ (void) saveWithBlockAndWait:(void(^)(NSManagedObjectContext *localContext))block;
{
    NSManagedObjectContext *savingContext  = [NSManagedObjectContext QM_rootSavingContext];
    NSManagedObjectContext *localContext = [NSManagedObjectContext QM_contextWithParent:savingContext];

    [localContext performBlockAndWait:^{
        [localContext QM_setWorkingName:NSStringFromSelector(_cmd)];

        if (block) {
            block(localContext);
        }

        [localContext QM_saveWithOptions:QMSaveParentContexts|QMSaveSynchronously completion:nil];
    }];
}

@end

#pragma mark - Deprecated Methods — DO NOT USE
@implementation QMMagicalRecord (ActionsDeprecated)

+ (void) saveUsingCurrentThreadContextWithBlock:(void (^)(NSManagedObjectContext *localContext))block completion:(QMSaveCompletionHandler)completion;
{
    NSManagedObjectContext *localContext = [NSManagedObjectContext QM_contextForCurrentThread];

    [localContext performBlock:^{
        [localContext QM_setWorkingName:NSStringFromSelector(_cmd)];

        if (block) {
            block(localContext);
        }

        [localContext QM_saveWithOptions:QMSaveParentContexts completion:completion];
    }];
}

+ (void) saveUsingCurrentThreadContextWithBlockAndWait:(void (^)(NSManagedObjectContext *localContext))block;
{
    NSManagedObjectContext *localContext = [NSManagedObjectContext QM_contextForCurrentThread];

    [localContext performBlockAndWait:^{
        [localContext QM_setWorkingName:NSStringFromSelector(_cmd)];

        if (block) {
            block(localContext);
        }

        [localContext QM_saveWithOptions:QMSaveParentContexts|QMSaveSynchronously completion:nil];
    }];
}

+ (void) saveInBackgroundWithBlock:(void(^)(NSManagedObjectContext *localContext))block
{
    [[self class] saveWithBlock:block completion:nil];
}

+ (void) saveInBackgroundWithBlock:(void(^)(NSManagedObjectContext *localContext))block completion:(void(^)(void))completion
{
    NSManagedObjectContext *savingContext  = [NSManagedObjectContext QM_rootSavingContext];
    NSManagedObjectContext *localContext = [NSManagedObjectContext QM_contextWithParent:savingContext];

    [localContext performBlock:^{
        [localContext QM_setWorkingName:NSStringFromSelector(_cmd)];

        if (block)
        {
            block(localContext);
        }

        [localContext QM_saveToPersistentStoreAndWait];

        if (completion)
        {
            completion();
        }
    }];
}

+ (void) saveInBackgroundUsingCurrentContextWithBlock:(void (^)(NSManagedObjectContext *localContext))block completion:(void (^)(void))completion errorHandler:(void (^)(NSError *error))errorHandler;
{
    NSManagedObjectContext *localContext = [NSManagedObjectContext QM_contextForCurrentThread];

    [localContext performBlock:^{
        [localContext QM_setWorkingName:NSStringFromSelector(_cmd)];

        if (block) {
            block(localContext);
        }

        [localContext QM_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
            if (contextDidSave) {
                if (completion) {
                    completion();
                }
            }
            else {
                if (errorHandler) {
                    errorHandler(error);
                }
            }
        }];
    }];
}

@end
