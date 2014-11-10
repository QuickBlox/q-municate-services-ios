//
//  NSManagedObjectContext+QMMagicalObserving.m
//  QMMagical Record
//
//  Created by Saul Mora on 3/9/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import "NSManagedObjectContext+QMMagicalObserving.h"
#import "NSManagedObjectContext+QMMagicalRecord.h"
#import "QMMagicalRecord.h"
#import "QMMagicalRecord+iCloud.h"
#import "QMMagicalRecordLogging.h"

NSString * const kQMMagicalRecordDidMergeChangesFromiCloudNotification = @"kQMMagicalRecordDidMergeChangesFromiCloudNotification";

@implementation NSManagedObjectContext (QMMagicalObserving)

#pragma mark - Context Observation Helpers

- (void) QM_observeContext:(NSManagedObjectContext *)otherContext
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self
                           selector:@selector(QM_mergeChangesFromNotification:)
                               name:NSManagedObjectContextDidSaveNotification
                             object:otherContext];
}

- (void) QM_stopObservingContext:(NSManagedObjectContext *)otherContext
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

	[notificationCenter removeObserver:self
                                  name:NSManagedObjectContextDidSaveNotification
                                object:otherContext];
}

- (void) QM_observeContextOnMainThread:(NSManagedObjectContext *)otherContext
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self
                           selector:@selector(QM_mergeChangesOnMainThread:)
                               name:NSManagedObjectContextDidSaveNotification
                             object:otherContext];
}

#pragma mark - Context iCloud Merge Helpers

- (void) QM_mergeChangesFromiCloud:(NSNotification *)notification;
{
    [self performBlock:^{
        
        QMMRLogVerbose(@"Merging changes From iCloud %@context%@",
              self == [NSManagedObjectContext QM_defaultContext] ? @"*** DEFAULT *** " : @"",
              ([NSThread isMainThread] ? @" *** on Main Thread ***" : @""));
        
        [self mergeChangesFromContextDidSaveNotification:notification];
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

        [notificationCenter postNotificationName:kQMMagicalRecordDidMergeChangesFromiCloudNotification
                                          object:self
                                        userInfo:[notification userInfo]];
    }];
}

- (void) QM_mergeChangesFromNotification:(NSNotification *)notification;
{
	QMMRLogVerbose(@"Merging changes to %@context%@",
          self == [NSManagedObjectContext QM_defaultContext] ? @"*** DEFAULT *** " : @"",
          ([NSThread isMainThread] ? @" *** on Main Thread ***" : @""));
    
	[self mergeChangesFromContextDidSaveNotification:notification];
}

- (void) QM_mergeChangesOnMainThread:(NSNotification *)notification;
{
	if ([NSThread isMainThread])
	{
		[self QM_mergeChangesFromNotification:notification];
	}
	else
	{
		[self performSelectorOnMainThread:@selector(QM_mergeChangesFromNotification:) withObject:notification waitUntilDone:YES];
	}
}

- (void) QM_observeiCloudChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator;
{
    if (![QMMagicalRecord isICloudEnabled]) return;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(QM_mergeChangesFromiCloud:)
                               name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                             object:coordinator];
    
}

- (void) QM_stopObservingiCloudChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator;
{
    if (![QMMagicalRecord isICloudEnabled]) return;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                                  name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                object:coordinator];
}

@end
