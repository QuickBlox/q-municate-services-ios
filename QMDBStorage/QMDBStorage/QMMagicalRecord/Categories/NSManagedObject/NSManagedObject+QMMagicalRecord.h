//
//
//  Created by Saul Mora on 11/15/09.
//  Copyright 2010 QMMagical Panda Software, LLC All rights reserved.
//

#import <CoreData/CoreData.h>
#import "QMMagicalRecord.h"
#import "QMMagicalRecordDeprecated.h"

#define kQMMagicalRecordDefaultBatchSize 20

@interface NSManagedObject (QMMagicalRecord)

/**
 *  If the NSManagedObject subclass calling this method has implemented the `entityName` method, then the return value of that will be used.
 *  If `entityName` is not implemented, then the name of the class is returned.
 *
 *  @return String based name for the entity
 */
+ (NSString *) QM_entityName;

+ (NSUInteger) QM_defaultBatchSize;
+ (void) QM_setDefaultBatchSize:(NSUInteger)newBatchSize;

+ (NSArray *) QM_executeFetchRequest:(NSFetchRequest *)request;
+ (NSArray *) QM_executeFetchRequest:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context;
+ (instancetype) QM_executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request;
+ (instancetype) QM_executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context;

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

+ (void) QM_performFetch:(NSFetchedResultsController *)controller;

#endif

+ (NSEntityDescription *) QM_entityDescription;
+ (NSEntityDescription *) QM_entityDescriptionInContext:(NSManagedObjectContext *)context;
+ (NSArray *) QM_propertiesNamed:(NSArray *)properties;
+ (NSArray *) QM_propertiesNamed:(NSArray *)properties inContext:(NSManagedObjectContext *)context;

+ (instancetype) QM_createEntity;
+ (instancetype) QM_createEntityInContext:(NSManagedObjectContext *)context;

- (BOOL) QM_deleteEntity;
- (BOOL) QM_deleteEntityInContext:(NSManagedObjectContext *)context;

+ (BOOL) QM_deleteAllMatchingPredicate:(NSPredicate *)predicate;
+ (BOOL) QM_deleteAllMatchingPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;

+ (BOOL) QM_truncateAll;
+ (BOOL) QM_truncateAllInContext:(NSManagedObjectContext *)context;

+ (NSArray *) QM_ascendingSortDescriptors:(NSArray *)attributesToSortBy;
+ (NSArray *) QM_descendingSortDescriptors:(NSArray *)attributesToSortBy;

- (instancetype) QM_inContext:(NSManagedObjectContext *)otherContext;
- (instancetype) QM_inThreadContext;

@end

@protocol QMMagicalRecord_MOGenerator <NSObject>

@optional
+ (NSString *)entityName;
- (instancetype) entityInManagedObjectContext:(NSManagedObjectContext *)object;
- (instancetype) insertInManagedObjectContext:(NSManagedObjectContext *)object;

@end

#pragma mark - Deprecated Methods — DO NOT USE
@interface NSManagedObject (QMMagicalRecordDeprecated)

+ (instancetype) QM_createInContext:(NSManagedObjectContext *)context QM_DEPRECATED_WILL_BE_REMOVED_IN_PLEASE_USE("4.0", "QM_createEntityInContext:");
- (BOOL) QM_deleteInContext:(NSManagedObjectContext *)context QM_DEPRECATED_WILL_BE_REMOVED_IN_PLEASE_USE("4.0", "QM_deleteEntityInContext:");

@end
