//
//  NSManagedObjectContext+QMMagicalRecord.h
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2010 QMMagical Panda Software, LLC All rights reserved.
//

#import "QMMagicalRecord.h"
#import "QMMagicalRecordDeprecated.h"

@interface NSManagedObjectContext (QMMagicalRecord)

#pragma mark - Setup

/**
 Initializes QMMagicalRecord's default contexts using the provided persistent store coordinator.

 @param coordinator Persistent Store Coordinator
 */
+ (void) QM_initializeDefaultContextWithCoordinator:(NSPersistentStoreCoordinator *)coordinator;

#pragma mark - Default Contexts
/**
 Root context responsible for sending changes to the main persistent store coordinator that will be saved to disk.

 @discussion Use this context for making and saving changes. All saves will be merged into the context returned by `QM_defaultContext` as well.

 @return Private context used for saving changes to disk on a background thread
 */
+ (NSManagedObjectContext *) QM_rootSavingContext;

/**
 @discussion Please do not use this context for saving changes, as it will block the main thread when doing so.

 @return Main queue context that can be observed for changes
 */
+ (NSManagedObjectContext *) QM_defaultContext;

#pragma mark - Context Creation

/**
 Creates and returns a new managed object context of type `NSPrivateQueueConcurrencyType`, with it's parent context set to the root saving context.
 @return Private context with the parent set to the root saving context
 */
+ (NSManagedObjectContext *) QM_context;

/**
 Creates and returns a new managed object context of type `NSPrivateQueueConcurrencyType`, with it's parent context set to the root saving context.

 @param parentContext Context to set as the parent of the newly initialized context

 @return Private context with the parent set to the provided context
 */
+ (NSManagedObjectContext *) QM_contextWithParent:(NSManagedObjectContext *)parentContext;

/**
 Creates and returns a new managed object context of type `NSPrivateQueueConcurrencyType`, with it's persistent store coordinator set to the provided coordinator.
 
 @param coordinator A persistent store coordinator

 @return Private context with it's persistent store coordinator set to the provided coordinator
 */
+ (NSManagedObjectContext *) QM_contextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator;

/**
 Initializes a context of type `NSMainQueueConcurrencyType`.

 @return A context initialized using the `NSPrivateQueueConcurrencyType` concurrency type.
 */
+ (NSManagedObjectContext *) QM_newMainQueueContext NS_RETURNS_RETAINED;

/**
 Initializes a context of type `NSPrivateQueueConcurrencyType`.

 @return A context initialized using the `NSPrivateQueueConcurrencyType` concurrency type.
 */
+ (NSManagedObjectContext *) QM_newPrivateQueueContext NS_RETURNS_RETAINED;

#pragma mark - Debugging

/**
 Sets a working name for the context, which will be used in debug logs.

 @param workingName Name for the context
 */
- (void) QM_setWorkingName:(NSString *)workingName;

/**
 @return Working name for the context
 */
- (NSString *) QM_workingName;

/**
 @return Description of this context
 */
- (NSString *) QM_description;

/**
 @return Description of the parent contexts of this context
 */
- (NSString *) QM_parentChain;


#pragma mark - Helpers

/**
 Reset the default context.
 */
+ (void) QM_resetDefaultContext;

/**
 Delete the provided objects from the context

 @param objects An object conforming to `NSFastEnumeration`, containing NSManagedObject instances
 */
- (void) QM_deleteObjects:(id <NSFastEnumeration>)objects;

@end

#pragma mark - Deprecated Methods — DO NOT USE
@interface NSManagedObjectContext (QMMagicalRecordDeprecated)

+ (NSManagedObjectContext *) QM_contextWithoutParent QM_DEPRECATED_WILL_BE_REMOVED_IN_PLEASE_USE("4.0", "QM_newPrivateQueueContext");
+ (NSManagedObjectContext *) QM_newContext QM_DEPRECATED_WILL_BE_REMOVED_IN_PLEASE_USE("4.0", "QM_context");
+ (NSManagedObjectContext *) QM_newContextWithParent:(NSManagedObjectContext *)parentContext QM_DEPRECATED_WILL_BE_REMOVED_IN_PLEASE_USE("4.0", "QM_contextWithParent:");
+ (NSManagedObjectContext *) QM_newContextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator QM_DEPRECATED_WILL_BE_REMOVED_IN_PLEASE_USE("4.0", "QM_contextWithStoreCoordinator:");


@end
