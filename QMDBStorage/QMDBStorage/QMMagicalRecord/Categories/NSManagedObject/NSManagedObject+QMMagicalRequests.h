//
//  NSManagedObject+QMMagicalRequests.h
//  QMMagical Record
//
//  Created by Saul Mora on 3/7/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (QMMagicalRequests)

+ (NSFetchRequest *) QM_createFetchRequest;
+ (NSFetchRequest *) QM_createFetchRequestInContext:(NSManagedObjectContext *)context;

+ (NSFetchRequest *) QM_requestAll;
+ (NSFetchRequest *) QM_requestAllInContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) QM_requestAllWithPredicate:(NSPredicate *)searchTerm;
+ (NSFetchRequest *) QM_requestAllWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) QM_requestAllWhere:(NSString *)property isEqualTo:(id)value;
+ (NSFetchRequest *) QM_requestAllWhere:(NSString *)property isEqualTo:(id)value inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) QM_requestFirstWithPredicate:(NSPredicate *)searchTerm;
+ (NSFetchRequest *) QM_requestFirstWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) QM_requestFirstByAttribute:(NSString *)attribute withValue:(id)searchValue;
+ (NSFetchRequest *) QM_requestFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) QM_requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSFetchRequest *) QM_requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) QM_requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm;
+ (NSFetchRequest *) QM_requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;


@end
