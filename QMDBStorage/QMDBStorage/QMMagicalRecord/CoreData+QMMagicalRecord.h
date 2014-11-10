//
//  CoreData+QMMagicalRecord.h
//
//  Created by Saul Mora on 28/07/10.
//  Copyright 2010 QMMagical Panda Software, LLC All rights reserved.
//

#ifdef __OBJC__

    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>

    #ifndef NS_BLOCKS_AVAILABLE
    #warning QMMagicalRecord requires blocks
    #endif

    #ifdef QM_SHORTHAND
    #import "QMMagicalRecordShorthand.h"
    #endif

    #import "QMMagicalRecord.h"
    #import "QMMagicalRecordDeprecated.h"
    #import "QMMagicalRecord+Actions.h"
    #import "QMMagicalRecord+ErrorHandling.h"
    #import "QMMagicalRecord+Options.h"
    #import "QMMagicalRecord+ShorthandSupport.h"
    #import "QMMagicalRecord+Setup.h"
    #import "QMMagicalRecord+iCloud.h"

    #import "NSManagedObject+QMMagicalRecord.h"
    #import "NSManagedObject+QMMagicalRequests.h"
    #import "NSManagedObject+QMMagicalFinders.h"
    #import "NSManagedObject+QMMagicalAggregation.h"
    #import "NSManagedObjectContext+QMMagicalRecord.h"
    #import "NSManagedObjectContext+QMMagicalObserving.h"
    #import "NSManagedObjectContext+QMMagicalSaves.h"
    #import "NSManagedObjectContext+QMMagicalThreading.h"
    #import "NSPersistentStoreCoordinator+QMMagicalRecord.h"
    #import "NSManagedObjectModel+QMMagicalRecord.h"
    #import "NSPersistentStore+QMMagicalRecord.h"

    #import "QMMagicalImportFunctions.h"
    #import "NSManagedObject+QMMagicalDataImport.h"
    #import "NSNumber+QMMagicalDataImport.h"
    #import "NSObject+QMMagicalDataImport.h"
    #import "NSString+QMMagicalDataImport.h"
    #import "NSAttributeDescription+QMMagicalDataImport.h"
    #import "NSRelationshipDescription+QMMagicalDataImport.h"
    #import "NSEntityDescription+QMMagicalDataImport.h"

#endif

// @see https://github.com/ccgus/fmdb/commit/aef763eeb64e6fa654e7d121f1df4c16a98d9f4f
#define QMMRDispatchQueueRelease(q) (dispatch_release(q))

#if TARGET_OS_IPHONE
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
        #undef QMMRDispatchQueueRelease
        #define QMMRDispatchQueueRelease(q)
    #endif
#else
    #if MAC_OS_X_VERSION_MIN_REQUIRED >= 1080
        #undef QMMRDispatchQueueRelease
        #define QmMRDispatchQueueRelease(q)
    #endif
#endif
