//
//  NSManagedObjectContext+QMMagicalObserving.h
//  QMMagical Record
//
//  Created by Saul Mora on 3/9/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

extern NSString * const kQMMagicalRecordDidMergeChangesFromiCloudNotification;

/**
 Category methods to aid in observing changes in other contexts.

 @since Available in v2.0 and later.
 */
@interface NSManagedObjectContext (QMMagicalObserving)

/**
 Merge changes from another context into self.

 @param otherContext Managed object context to observe.

 @since Available in v2.0 and later.
 */
- (void) QM_observeContext:(NSManagedObjectContext *)otherContext;

/**
 Stops merging changes from the supplied context into self.

 @param otherContext Managed object context to stop observing.

 @since Available in v2.0 and later.
 */
- (void) QM_stopObservingContext:(NSManagedObjectContext *)otherContext;

/**
 Merges changes from another context into self on the main thread.

 @param otherContext Managed object context to observe.

 @since Available in v2.0 and later.
 */
- (void) QM_observeContextOnMainThread:(NSManagedObjectContext *)otherContext;

/**
 Merges changes from the supplied persistent store coordinator into self in response to changes from iCloud.

 @param coordinator Persistent store coordinator

 @see -QM_stopObservingiCloudChangesInCoordinator:

 @since Available in v2.0 and later.
 */
- (void) QM_observeiCloudChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator;

/**
 Stops observation and merging of changes from the supplied persistent store coordinator in response to changes from iCloud.

 @param coordinator Persistent store coordinator

 @see -QM_observeiCloudChangesInCoordinator:

 @since Available in v2.0 and later.
 */
- (void) QM_stopObservingiCloudChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator;

@end
