//
//  QMMagicalRecord+Options.h
//  QMMagical Record
//
//  Created by Saul Mora on 3/6/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import "QMMagicalRecord.h"

/**
 Defines "levels" of logging that will be used as values in a bitmask that filters log messages.

 @since Available in v2.3 and later.
 */
typedef NS_ENUM (NSInteger, QMMagicalRecordLoggingMask)
{
    /** Disable all logging */
    QMMagicalRecordLoggingMaskOff = 0,

    /** Log fatal errors */
    QMMagicalRecordLoggingMaskFatal = 1 << 0,

    /** Log all errors */
    QMMagicalRecordLoggingMaskError = 1 << 1,

    /** Log warnings, and all errors */
    QMMagicalRecordLoggingMaskWarn = 1 << 2,

    /** Log informative messagess, warnings and all errors */
    QMMagicalRecordLoggingMaskInfo = 1 << 3,

    /** Log verbose diagnostic information, messages, warnings and all errors */
    QMMagicalRecordLoggingMaskVerbose = 1 << 4,
};

/**
 Defines a mask for logging that will be used by to filter log messages.

 @since Available in v2.3 and later.
 */
typedef NS_ENUM (NSInteger, QMMagicalRecordLoggingLevel)
{
    /** Don't log anything */
    QMMagicalRecordLoggingLevelOff = 0,

    /** Log all fatal messages */
    QMMagicalRecordLoggingLevelFatal = (QMMagicalRecordLoggingMaskFatal),

    /** Log all errors and fatal messages */
    QMMagicalRecordLoggingLevelError = (QMMagicalRecordLoggingMaskFatal | QMMagicalRecordLoggingMaskError),

    /** Log warnings, errors and fatal messages */
    QMMagicalRecordLoggingLevelWarn = (QMMagicalRecordLoggingMaskFatal | QMMagicalRecordLoggingMaskError | QMMagicalRecordLoggingMaskWarn),

    /** Log informative, warning and error messages */
    QMMagicalRecordLoggingLevelInfo = (QMMagicalRecordLoggingMaskFatal | QMMagicalRecordLoggingMaskError | QMMagicalRecordLoggingMaskWarn | QMMagicalRecordLoggingMaskInfo),

    /** Log verbose diagnostic, informative, warning and error messages */
    QMMagicalRecordLoggingLevelVerbose = (QMMagicalRecordLoggingMaskFatal | QMMagicalRecordLoggingMaskError | QMMagicalRecordLoggingMaskWarn | QMMagicalRecordLoggingMaskInfo | QMMagicalRecordLoggingMaskVerbose),
};


@interface QMMagicalRecord (Options)

/**
 @name Configuration Options
 */

/**
 If this is true, the default managed object model will be automatically created if it doesn't exist when calling `[NSManagedObjectModel QM_defaultManagedObjectModel]`.

 @return current value of shouldAutoCreateManagedObjectModel.

 @since Available in v2.0.4 and later.
 */
+ (BOOL) shouldAutoCreateManagedObjectModel;

/**
 Setting this to true will make QMMagicalRecord create the default managed object model automatically if it doesn't exist when calling `[NSManagedObjectModel QM_defaultManagedObjectModel]`.

 @param autoCreate BOOL value that flags whether the default persistent store should be automatically created.

 @since Available in v2.0.4 and later.
 */
+ (void) setShouldAutoCreateManagedObjectModel:(BOOL)autoCreate;

/**
 If this is true, the default persistent store will be automatically created if it doesn't exist when calling `[NSPersistentStoreCoordinator QM_defaultStoreCoordinator]`.

 @return current value of shouldAutoCreateDefaultPersistentStoreCoordinator.

 @since Available in v2.0.4 and later.
 */
+ (BOOL) shouldAutoCreateDefaultPersistentStoreCoordinator;

/**
 Setting this to true will make QMMagicalRecord create the default persistent store automatically if it doesn't exist when calling `[NSPersistentStoreCoordinator QM_defaultStoreCoordinator]`.

 @param autoCreate BOOL value that flags whether the default persistent store should be automatically created.

 @since Available in v2.0.4 and later.
 */
+ (void) setShouldAutoCreateDefaultPersistentStoreCoordinator:(BOOL)autoCreate;

/**
 If this is true and QMMagicalRecord encounters a store with a version that does not match that of the model, the store will be removed from the disk.
 This is extremely useful during development where frequent model changes can potentially require a delete and reinstall of the app.

 @return current value of shouldDeleteStoreOnModelMismatch
 
 @since Available in v2.0.4 and later.
 */
+ (BOOL) shouldDeleteStoreOnModelMismatch;

/**
 Setting this to true will make QMMagicalRecord delete any stores that it encounters which do not match the version of their model.
 This is extremely useful during development where frequent model changes can potentially require a delete and reinstall of the app.

 @param shouldDelete BOOL value that flags whether mismatched stores should be deleted
 
 @since Available in v2.0.4 and later.
 */
+ (void) setShouldDeleteStoreOnModelMismatch:(BOOL)shouldDelete;

/**
 @name Logging Levels
 */

/**
 Returns the logging mask set for QMMagicalRecord in the current application.

 @return Current QMMagicalRecordLoggingLevel
 
 @since Available in v2.3 and later.
 */
+ (QMMagicalRecordLoggingLevel) loggingLevel;

/**
 Sets the logging mask set for QMMagicalRecord in the current application.

 @param level Any value from QMMagicalRecordLogLevel

 @since Available in v2.3 and later.
 */
+ (void) setLoggingLevel:(QMMagicalRecordLoggingLevel)level;

@end
