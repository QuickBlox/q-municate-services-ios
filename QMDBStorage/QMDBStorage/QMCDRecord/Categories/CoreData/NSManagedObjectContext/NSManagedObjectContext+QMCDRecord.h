//
//  NSManagedObjectContext+QMCDRecord.h
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2010 QMCD Panda Software, LLC All rights reserved.
//

#import <CoreData/CoreData.h>

extern NSString * const QMCDRecordDidMergeChangesFromiCloudNotification;

@interface NSManagedObjectContext (QMCDRecord)

- (void) QM_obtainPermanentIDsForObjects:(NSArray *)objects;

+ (NSManagedObjectContext *) QM_context NS_RETURNS_RETAINED;
+ (NSManagedObjectContext *) QM_mainQueueContext;
+ (NSManagedObjectContext *) QM_privateQueueContext;

+ (NSManagedObjectContext *) QM_confinementContext;
+ (NSManagedObjectContext *) QM_confinementContextWithParent:(NSManagedObjectContext *)parentContext;

+ (NSManagedObjectContext *) QM_privateQueueContextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator NS_RETURNS_RETAINED;

- (NSString *) QM_description;
- (NSString *) QM_parentChain;

- (void) QM_setWorkingName:(NSString *)workingName;
- (NSString *) QM_workingName;

@end
