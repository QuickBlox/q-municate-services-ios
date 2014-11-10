//
//  NSManagedObjectContext+QMMagicalSaves.m
//  QMMagical Record
//
//  Created by Saul Mora on 3/9/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import "NSManagedObjectContext+QMMagicalSaves.h"
#import "QMMagicalRecord+ErrorHandling.h"
#import "NSManagedObjectContext+QMMagicalRecord.h"
#import "QMMagicalRecord.h"
#import "QMMagicalRecordLogging.h"

@implementation NSManagedObjectContext (QMMagicalSaves)

- (void) QM_saveOnlySelfWithCompletion:(QMSaveCompletionHandler)completion;
{
    [self QM_saveWithOptions:QMSaveOptionNone completion:completion];
}

- (void) QM_saveOnlySelfAndWait;
{
    [self QM_saveWithOptions:QMSaveSynchronously completion:nil];
}

- (void) QM_saveToPersistentStoreWithCompletion:(QMSaveCompletionHandler)completion;
{
    [self QM_saveWithOptions:QMSaveParentContexts completion:completion];
}

- (void) QM_saveToPersistentStoreAndWait;
{
    [self QM_saveWithOptions:QMSaveParentContexts | QMSaveSynchronously completion:nil];
}

- (void) QM_saveWithOptions:(QMSaveOptions)saveOptions completion:(QMSaveCompletionHandler)completion;
{
    __block BOOL hasChanges = NO;

    if ([self concurrencyType] == NSConfinementConcurrencyType)
    {
        hasChanges = [self hasChanges];
    }
    else
    {
        [self performBlockAndWait:^{
            hasChanges = [self hasChanges];
        }];
    }

    if (!hasChanges)
    {
        QMMRLogVerbose(@"NO CHANGES IN ** %@ ** CONTEXT - NOT SAVING", [self QM_workingName]);

        if (completion)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil);
            });
        }

        return;
    }

    BOOL shouldSaveParentContexts = ((saveOptions & QMSaveParentContexts) == QMSaveParentContexts);
    BOOL shouldSaveSynchronously = ((saveOptions & QMSaveSynchronously) == QMSaveSynchronously);
    BOOL shouldSaveSynchronouslyExceptRoot = ((saveOptions & QMSaveSynchronouslyExceptRootContext) == QMSaveSynchronouslyExceptRootContext);

    BOOL saveSynchronously = (shouldSaveSynchronously && !shouldSaveSynchronouslyExceptRoot) ||
                             (shouldSaveSynchronouslyExceptRoot && (self != [[self class] QM_rootSavingContext]));

    id saveBlock = ^{
        QMMRLogInfo(@"→ Saving %@", [self QM_description]);
        QMMRLogVerbose(@"→ Save Parents? %@", shouldSaveParentContexts ? @"YES" : @"NO");
        QMMRLogVerbose(@"→ Save Synchronously? %@", saveSynchronously ? @"YES" : @"NO");

        BOOL saveResult = NO;
        NSError *error = nil;

        @try
        {
            saveResult = [self save:&error];
        }
        @catch(NSException *exception)
        {
            QMMRLogError(@"Unable to perform save: %@", (id)[exception userInfo] ?: (id)[exception reason]);
        }
        @finally
        {
            [QMMagicalRecord handleErrors:error];

            if (saveResult && shouldSaveParentContexts && [self parentContext])
            {
                // Add/remove the synchronous save option from the mask if necessary
                QMSaveOptions modifiedOptions = saveOptions;

                if (saveSynchronously)
                {
                    modifiedOptions |= QMSaveSynchronously;
                }
                else
                {
                    modifiedOptions &= QMSaveSynchronously;
                }

                // If we're saving parent contexts, do so
                [[self parentContext] QM_saveWithOptions:modifiedOptions completion:completion];
            }
            else
            {
                if (saveResult)
                {
                    QMMRLogVerbose(@"→ Finished saving: %@", [self QM_description]);
                }

                if (completion)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(saveResult, error);
                    });
                }
            }
        }
    };

    if (saveSynchronously)
    {
        [self performBlockAndWait:saveBlock];
    }
    else
    {
        [self performBlock:saveBlock];
    }
}

@end

