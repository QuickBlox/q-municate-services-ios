//
//  Created by Injoit on 3/11/10.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//


#ifdef __OBJC__
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#ifndef NS_BLOCKS_AVAILABLE
#warning QMCDRecord requires blocks
#endif

#import "QMCDRecordInternal.h"
#import "QMCDRecord+Options.h"
#import "QMCDRecord+Setup.h"
#import "QMCDRecord+VersionInformation.h"

#import "QMCDRecordStack.h"
#import "QMCDRecordStack+Actions.h"
#import "SQLiteQMCDRecordStack.h"
#import "SQLiteWithSavingContextQMCDRecordStack.h"
#import "ClassicSQLiteQMCDRecordStack.h"
#import "ClassicWithBackgroundCoordinatorSQLiteQMCDRecordStack.h"

#import "InMemoryQMCDRecordStack.h"

#import "AutoMigratingQMCDRecordStack.h"
#import "AutoMigratingWithSourceAndTargetModelQMCDRecordStack.h"
#import "ManuallyMigratingQMCDRecordStack.h"

#import "NSArray+QMCDRecord.h"

#import "NSManagedObject+QMCDRecord.h"
#import "NSManagedObject+QMCDRequests.h"
#import "NSManagedObject+QMCDFinders.h"
#import "NSManagedObject+QMCDAggregation.h"
#import "NSManagedObjectContext+QMCDRecord.h"
#import "NSManagedObjectContext+QMCDObserving.h"
#import "NSManagedObjectContext+QMCDSaves.h"

#import "NSPersistentStoreCoordinator+QMCDRecord.h"
#import "NSPersistentStoreCoordinator+QMCDAutoMigrations.h"
#import "NSPersistentStoreCoordinator+QMCDManualMigrations.h"
#import "NSPersistentStoreCoordinator+QMCDInMemoryStoreAdditions.h"

#import "NSManagedObjectModel+QMCDRecord.h"
#import "NSPersistentStore+QMCDRecord.h"

#import "QMCDImportFunctions.h"
#import "NSError+QMCDRecordErrorHandling.h"


#define QM_SHORTHAND 1
#import "QMCDRecordShorthand.h"

#endif // ifdef __OBJC__
