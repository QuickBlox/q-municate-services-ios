//
//  NSManagedObject+QMMagicalAggregation.h
//  QMMagical Record
//
//  Created by Saul Mora on 3/7/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (QMMagicalAggregation)

+ (NSNumber *) QM_numberOfEntities;
+ (NSNumber *) QM_numberOfEntitiesWithContext:(NSManagedObjectContext *)context;
+ (NSNumber *) QM_numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm;
+ (NSNumber *) QM_numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;

+ (NSUInteger) QM_countOfEntities;
+ (NSUInteger) QM_countOfEntitiesWithContext:(NSManagedObjectContext *)context;
+ (NSUInteger) QM_countOfEntitiesWithPredicate:(NSPredicate *)searchFilter;
+ (NSUInteger) QM_countOfEntitiesWithPredicate:(NSPredicate *)searchFilter inContext:(NSManagedObjectContext *)context;

+ (BOOL) QM_hasAtLeastOneEntity;
+ (BOOL) QM_hasAtLeastOneEntityInContext:(NSManagedObjectContext *)context;

- (id) QM_minValueFor:(NSString *)property;
- (id) QM_maxValueFor:(NSString *)property;

+ (id) QM_aggregateOperation:(NSString *)function onAttribute:(NSString *)attributeName withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;
+ (id) QM_aggregateOperation:(NSString *)function onAttribute:(NSString *)attributeName withPredicate:(NSPredicate *)predicate;

/**
 *  Supports aggregating values using a key-value collection operator that can be grouped by an attribute.
 *  See https://developer.apple.com/library/ios/documentation/cocoa/conceptual/KeyValueCoding/Articles/CollectionOperators.html for a list of valid collection operators.
 *
 *  @since 2.3.0
 *
 *  @param collectionOperator   Collection operator
 *  @param attributeName        Entity attribute to apply the collection operator to
 *  @param predicate            Predicate to filter results
 *  @param groupingKeyPath      Key path to group results by
 *  @param context              Context to perform the request in
 *
 *  @return Results of the collection operator, filtered by the provided predicate and grouped by the provided key path
 */
+ (NSArray *) QM_aggregateOperation:(NSString *)collectionOperator onAttribute:(NSString *)attributeName withPredicate:(NSPredicate *)predicate groupBy:(NSString*)groupingKeyPath inContext:(NSManagedObjectContext *)context;

/**
 *  Supports aggregating values using a key-value collection operator that can be grouped by an attribute.
 *  See https://developer.apple.com/library/ios/documentation/cocoa/conceptual/KeyValueCoding/Articles/CollectionOperators.html for a list of valid collection operators.
 *
 *  This method is run against the default QMMagicalRecordStack's context.
 *
 *  @since 2.3.0
 *
 *  @param collectionOperator   Collection operator
 *  @param attributeName        Entity attribute to apply the collection operator to
 *  @param predicate            Predicate to filter results
 *  @param groupingKeyPath      Key path to group results by
 *
 *  @return Results of the collection operator, filtered by the provided predicate and grouped by the provided key path
 */
+ (NSArray *) QM_aggregateOperation:(NSString *)collectionOperator onAttribute:(NSString *)attributeName withPredicate:(NSPredicate *)predicate groupBy:(NSString*)groupingKeyPath;

- (instancetype) QM_objectWithMinValueFor:(NSString *)property;
- (instancetype) QM_objectWithMinValueFor:(NSString *)property inContext:(NSManagedObjectContext *)context;

@end
