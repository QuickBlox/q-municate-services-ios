    //
//  NSManagedObject+QMMagicalFinders.m
//  QMMagical Record
//
//  Created by Saul Mora on 3/7/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import "NSManagedObject+QMMagicalFinders.h"
#import "NSManagedObject+QMMagicalRequests.h"
#import "NSManagedObject+QMMagicalRecord.h"
#import "NSManagedObjectContext+QMMagicalThreading.h"

@implementation NSManagedObject (QMMagicalFinders)

#pragma mark - Finding Data


+ (NSArray *) QM_findAllInContext:(NSManagedObjectContext *)context
{
	return [self QM_executeFetchRequest:[self QM_requestAllInContext:context] inContext:context];
}

+ (NSArray *) QM_findAll
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_findAllInContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (NSArray *) QM_findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self QM_requestAllSortedBy:sortTerm ascending:ascending inContext:context];
	
	return [self QM_executeFetchRequest:request inContext:context];
}

+ (NSArray *) QM_findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_findAllSortedBy:sortTerm
                          ascending:ascending 
                          inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (NSArray *) QM_findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self QM_requestAllSortedBy:sortTerm
                                                ascending:ascending
                                            withPredicate:searchTerm
                                                inContext:context];
	
	return [self QM_executeFetchRequest:request inContext:context];
}

+ (NSArray *) QM_findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_findAllSortedBy:sortTerm
                          ascending:ascending
                      withPredicate:searchTerm 
                          inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}


+ (NSArray *) QM_findAllWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self QM_createFetchRequestInContext:context];
	[request setPredicate:searchTerm];
	
	return [self QM_executeFetchRequest:request
                              inContext:context];
}

+ (NSArray *) QM_findAllWithPredicate:(NSPredicate *)searchTerm
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_findAllWithPredicate:searchTerm
                               inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (instancetype) QM_findFirstInContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self QM_createFetchRequestInContext:context];
	
	return [self QM_executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (instancetype) QM_findFirst
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_findFirstInContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (instancetype) QM_findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context
{	
	NSFetchRequest *request = [self QM_requestFirstByAttribute:attribute withValue:searchValue inContext:context];
    //    [request setPropertiesToFetch:[NSArray arrayWithObject:attribute]];
    
	return [self QM_executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (instancetype) QM_findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_findFirstByAttribute:attribute
                               withValue:searchValue 
                               inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (instancetype) QM_findFirstOrderedByAttribute:(NSString *)attribute ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
{
    NSFetchRequest *request = [self QM_requestAllSortedBy:attribute ascending:ascending inContext:context];
    [request setFetchLimit:1];

    return [self QM_executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (instancetype) QM_findFirstOrderedByAttribute:(NSString *)attribute ascending:(BOOL)ascending;
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self QM_findFirstOrderedByAttribute:attribute
                                      ascending:ascending
                                      inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (instancetype) QM_findFirstOrCreateByAttribute:(NSString *)attribute withValue:(id)searchValue
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self QM_findFirstOrCreateByAttribute:attribute
                                       withValue:searchValue
                                       inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (instancetype) QM_findFirstOrCreateByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context
{
    id result = [self QM_findFirstByAttribute:attribute
                                    withValue:searchValue
                                    inContext:context];

    if (result != nil) {
        return result;
    }

    result = [self QM_createEntityInContext:context];
    [result setValue:searchValue forKey:attribute];

    return result;
}

+ (instancetype) QM_findFirstWithPredicate:(NSPredicate *)searchTerm
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self QM_findFirstWithPredicate:searchTerm inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (instancetype) QM_findFirstWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self QM_requestFirstWithPredicate:searchTerm inContext:context];
    
    return [self QM_executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (instancetype) QM_findFirstWithPredicate:(NSPredicate *)searchterm sortedBy:(NSString *)property ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self QM_requestAllSortedBy:property ascending:ascending withPredicate:searchterm inContext:context];
    
	return [self QM_executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (instancetype) QM_findFirstWithPredicate:(NSPredicate *)searchterm sortedBy:(NSString *)property ascending:(BOOL)ascending
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_findFirstWithPredicate:searchterm
                                  sortedBy:property 
                                 ascending:ascending 
                                 inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (instancetype) QM_findFirstWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self QM_createFetchRequestInContext:context];
	[request setPredicate:searchTerm];
	[request setPropertiesToFetch:attributes];
	
	return [self QM_executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (instancetype) QM_findFirstWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_findFirstWithPredicate:searchTerm
                     andRetrieveAttributes:attributes 
                                 inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (instancetype) QM_findFirstWithPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortBy ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context andRetrieveAttributes:(id)attributes, ...
{
	NSFetchRequest *request = [self QM_requestAllSortedBy:sortBy
                                                ascending:ascending
                                            withPredicate:searchTerm
                                                inContext:context];
	[request setPropertiesToFetch:[self QM_propertiesNamed:attributes inContext:context]];
	
	return [self QM_executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (instancetype) QM_findFirstWithPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortBy ascending:(BOOL)ascending andRetrieveAttributes:(id)attributes, ...
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_findFirstWithPredicate:searchTerm
                                  sortedBy:sortBy 
                                 ascending:ascending 
                                 inContext:[NSManagedObjectContext QM_contextForCurrentThread]
                     andRetrieveAttributes:attributes];
#pragma clang diagnostic pop
}

+ (NSArray *) QM_findByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self QM_requestAllWhere:attribute isEqualTo:searchValue inContext:context];
	
	return [self QM_executeFetchRequest:request inContext:context];
}

+ (NSArray *) QM_findByAttribute:(NSString *)attribute withValue:(id)searchValue
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_findByAttribute:attribute
                          withValue:searchValue 
                          inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (NSArray *) QM_findByAttribute:(NSString *)attribute withValue:(id)searchValue andOrderBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
	NSPredicate *searchTerm = [NSPredicate predicateWithFormat:@"%K = %@", attribute, searchValue];
	NSFetchRequest *request = [self QM_requestAllSortedBy:sortTerm ascending:ascending withPredicate:searchTerm inContext:context];
	
	return [self QM_executeFetchRequest:request inContext:context];
}

+ (NSArray *) QM_findByAttribute:(NSString *)attribute withValue:(id)searchValue andOrderBy:(NSString *)sortTerm ascending:(BOOL)ascending
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_findByAttribute:attribute
                          withValue:searchValue
                         andOrderBy:sortTerm 
                          ascending:ascending 
                          inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}


#pragma mark -
#pragma mark NSFetchedResultsController helpers


#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

+ (NSFetchedResultsController *) QM_fetchController:(NSFetchRequest *)request delegate:(id<NSFetchedResultsControllerDelegate>)delegate useFileCache:(BOOL)useFileCache groupedBy:(NSString *)groupKeyPath inContext:(NSManagedObjectContext *)context;
{
    NSString *cacheName = useFileCache ? [NSString stringWithFormat:@"QMMagicalRecord-Cache-%@", NSStringFromClass([self class])] : nil;
    
	NSFetchedResultsController *controller =
    [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                        managedObjectContext:context
                                          sectionNameKeyPath:groupKeyPath
                                                   cacheName:cacheName];
    controller.delegate = delegate;
    
    return controller;
}

+ (NSFetchedResultsController *) QM_fetchAllWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate;
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self QM_fetchAllWithDelegate:delegate inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (NSFetchedResultsController *) QM_fetchAllWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate inContext:(NSManagedObjectContext *)context;
{
    NSFetchRequest *request = [self QM_requestAllInContext:context];
    NSFetchedResultsController *controller = [self QM_fetchController:request delegate:delegate useFileCache:NO groupedBy:nil inContext:context];

    [self QM_performFetch:controller];
    return controller;
}

+ (NSFetchedResultsController *) QM_fetchAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending delegate:(id<NSFetchedResultsControllerDelegate>)delegate inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self QM_requestAllSortedBy:sortTerm 
                                                ascending:ascending 
                                            withPredicate:searchTerm
                                                inContext:context];
    
    NSFetchedResultsController *controller = [self QM_fetchController:request 
                                                             delegate:delegate
                                                         useFileCache:NO
                                                            groupedBy:group
                                                            inContext:context];
    
    [self QM_performFetch:controller];
    return controller;
}

+ (NSFetchedResultsController *) QM_fetchAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending delegate:(id)delegate
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_fetchAllGroupedBy:group
                        withPredicate:searchTerm
                             sortedBy:sortTerm
                            ascending:ascending
                             delegate:delegate
                            inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (NSFetchedResultsController *) QM_fetchAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
{
    return [self QM_fetchAllGroupedBy:group 
                        withPredicate:searchTerm
                             sortedBy:sortTerm
                            ascending:ascending
                             delegate:nil
                            inContext:context];
}

+ (NSFetchedResultsController *) QM_fetchAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending 
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self QM_fetchAllGroupedBy:group
                        withPredicate:searchTerm
                             sortedBy:sortTerm
                            ascending:ascending
                            inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}


+ (NSFetchedResultsController *) QM_fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self QM_requestAllSortedBy:sortTerm
                                                ascending:ascending
                                            withPredicate:searchTerm
                                                inContext:context];
	NSFetchedResultsController *controller = [self QM_fetchController:request
                                                             delegate:nil
                                                         useFileCache:NO
                                                            groupedBy:groupingKeyPath
                                                            inContext:context];

    [self QM_performFetch:controller];
    return controller;
}

+ (NSFetchedResultsController *) QM_fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath;
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self QM_fetchAllSortedBy:sortTerm
                           ascending:ascending
                       withPredicate:searchTerm
                             groupBy:groupingKeyPath
                           inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (NSFetchedResultsController *) QM_fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath delegate:(id<NSFetchedResultsControllerDelegate>)delegate inContext:(NSManagedObjectContext *)context
{
	return [self QM_fetchAllGroupedBy:groupingKeyPath
                        withPredicate:searchTerm
                             sortedBy:sortTerm
                            ascending:ascending
                             delegate:delegate
                            inContext:context];
}

+ (NSFetchedResultsController *) QM_fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath delegate:(id<NSFetchedResultsControllerDelegate>)delegate
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_fetchAllSortedBy:sortTerm
                           ascending:ascending
                       withPredicate:searchTerm 
                             groupBy:groupingKeyPath 
                            delegate:delegate
                           inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

#endif

@end
