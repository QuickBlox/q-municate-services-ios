
//  Created by Saul Mora on 11/15/09.
//  Copyright 2010 QMMagical Panda Software, LLC All rights reserved.
//

#import "CoreData+QMMagicalRecord.h"
#import "QMMagicalRecordLogging.h"

static NSUInteger defaultBatchSize = kQMMagicalRecordDefaultBatchSize;


@implementation NSManagedObject (QMMagicalRecord)

+ (NSString *) QM_entityName;
{
    NSString *entityName;

    if ([self respondsToSelector:@selector(entityName)])
    {
        entityName = [self performSelector:@selector(entityName)];
    }

    if ([entityName length] == 0) {
        entityName = NSStringFromClass(self);
    }

    return entityName;
}

+ (void) QM_setDefaultBatchSize:(NSUInteger)newBatchSize
{
	@synchronized(self)
	{
		defaultBatchSize = newBatchSize;
	}
}

+ (NSUInteger) QM_defaultBatchSize
{
	return defaultBatchSize;
}

+ (NSArray *) QM_executeFetchRequest:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context
{
    __block NSArray *results = nil;
    [context performBlockAndWait:^{

        NSError *error = nil;
        
        results = [context executeFetchRequest:request error:&error];
        
        if (results == nil) 
        {
            [QMMagicalRecord handleErrors:error];
        }

    }];
	return results;	
}

+ (NSArray *) QM_executeFetchRequest:(NSFetchRequest *)request
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_executeFetchRequest:request inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (id) QM_executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context
{
	[request setFetchLimit:1];
	
	NSArray *results = [self QM_executeFetchRequest:request inContext:context];
	if ([results count] == 0)
	{
		return nil;
	}
	return [results firstObject];
}

+ (id) QM_executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_executeFetchRequestAndReturnFirstObject:request inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

#if TARGET_OS_IPHONE

+ (void) QM_performFetch:(NSFetchedResultsController *)controller
{
	NSError *error = nil;
	if (![controller performFetch:&error])
	{
		[QMMagicalRecord handleErrors:error];
	}
}

#endif

+ (NSEntityDescription *) QM_entityDescription
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self QM_entityDescriptionInContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (NSEntityDescription *) QM_entityDescriptionInContext:(NSManagedObjectContext *)context
{
    NSString *entityName = [self QM_entityName];
    return [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
}

+ (NSArray *) QM_propertiesNamed:(NSArray *)properties
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self QM_propertiesNamed:properties inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (NSArray *) QM_propertiesNamed:(NSArray *)properties inContext:(NSManagedObjectContext *)context
{
	NSEntityDescription *description = [self QM_entityDescriptionInContext:context];
	NSMutableArray *propertiesWanted = [NSMutableArray array];

	if (properties)
	{
		NSDictionary *propDict = [description propertiesByName];

		for (NSString *propertyName in properties)
		{
			NSPropertyDescription *property = [propDict objectForKey:propertyName];
			if (property)
			{
				[propertiesWanted addObject:property];
			}
			else
			{
				QMMRLogWarn(@"Property '%@' not found in %lx properties for %@", propertyName, (unsigned long)[propDict count], NSStringFromClass(self));
			}
		}
	}
	return propertiesWanted;
}

+ (NSArray *) QM_sortAscending:(BOOL)ascending attributes:(NSArray *)attributesToSortBy
{
	NSMutableArray *attributes = [NSMutableArray array];
    
    for (NSString *attributeName in attributesToSortBy) 
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:attributeName ascending:ascending];
        [attributes addObject:sortDescriptor];
    }
    
	return attributes;
}

+ (NSArray *) QM_ascendingSortDescriptors:(NSArray *)attributesToSortBy
{
	return [self QM_sortAscending:YES attributes:attributesToSortBy];
}

+ (NSArray *) QM_descendingSortDescriptors:(NSArray *)attributesToSortBy
{
	return [self QM_sortAscending:NO attributes:attributesToSortBy];
}

#pragma mark -

+ (id) QM_createEntityInContext:(NSManagedObjectContext *)context
{
    if ([self respondsToSelector:@selector(insertInManagedObjectContext:)] && context != nil)
    {
        id entity = [self performSelector:@selector(insertInManagedObjectContext:) withObject:context];
        return entity;
    }
    else
    {
        NSEntityDescription *entity = nil;
        if (context == nil)
        {
            entity = [self QM_entityDescription];
        }
        else
        {
            entity  = [self QM_entityDescriptionInContext:context];
        }
        
        if (entity == nil)
        {
            return nil;
        }
        
        return [[self alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    }
}

+ (id) QM_createEntity
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	NSManagedObject *newEntity = [self QM_createEntityInContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop

	return newEntity;
}

- (BOOL) QM_deleteEntityInContext:(NSManagedObjectContext *)context
{
    NSError *error = nil;
    NSManagedObject *inContext = [context existingObjectWithID:[self objectID] error:&error];

    [QMMagicalRecord handleErrors:error];

    [context deleteObject:inContext];
    
    return YES;
}

- (BOOL) QM_deleteEntity
{
	[self QM_deleteEntityInContext:[self managedObjectContext]];
	return YES;
}

+ (BOOL) QM_deleteAllMatchingPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self QM_requestAllWithPredicate:predicate inContext:context];
    [request setReturnsObjectsAsFaults:YES];
	[request setIncludesPropertyValues:NO];
    
	NSArray *objectsToTruncate = [self QM_executeFetchRequest:request inContext:context];
    
	for (id objectToTruncate in objectsToTruncate) 
    {
		[objectToTruncate QM_deleteInContext:context];
	}
    
	return YES;
}

+ (BOOL) QM_deleteAllMatchingPredicate:(NSPredicate *)predicate
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self QM_deleteAllMatchingPredicate:predicate inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (BOOL) QM_truncateAllInContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self QM_requestAllInContext:context];
    [request setReturnsObjectsAsFaults:YES];
    [request setIncludesPropertyValues:NO];

    NSArray *objectsToDelete = [self QM_executeFetchRequest:request inContext:context];
    for (NSManagedObject *objectToDelete in objectsToDelete)
    {
        [objectToDelete QM_deleteEntityInContext:context];
    }
    return YES;
}

+ (BOOL) QM_truncateAll
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self QM_truncateAllInContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop

    return YES;
}

- (id) QM_inContext:(NSManagedObjectContext *)otherContext
{
    NSError *error = nil;
    
    if ([[self objectID] isTemporaryID])
    {
        BOOL success = [[self managedObjectContext] obtainPermanentIDsForObjects:@[self] error:&error];
        if (!success)
        {
            [QMMagicalRecord handleErrors:error];
            return nil;
        }
    }
    
    error = nil;
    
    NSManagedObject *inContext = [otherContext existingObjectWithID:[self objectID] error:&error];
    [QMMagicalRecord handleErrors:error];
    
    return inContext;
}

- (id) QM_inThreadContext
{
    NSManagedObject *weakSelf = self;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [weakSelf QM_inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

@end

#pragma mark - Deprecated Methods — DO NOT USE
@implementation NSManagedObject (QMMagicalRecordDeprecated)

+ (instancetype) QM_createInContext:(NSManagedObjectContext *)context
{
    return [self QM_createEntityInContext:context];
}

- (BOOL) QM_deleteInContext:(NSManagedObjectContext *)context
{
    return [self QM_deleteEntityInContext:context];
}

@end
