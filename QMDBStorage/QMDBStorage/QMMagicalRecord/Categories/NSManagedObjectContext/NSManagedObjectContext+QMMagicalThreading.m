//
//  NSManagedObjectContext+QMMagicalThreading.m
//  QMMagical Record
//
//  Created by Saul Mora on 3/9/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import "NSManagedObjectContext+QMMagicalThreading.h"
#import "NSManagedObject+QMMagicalRecord.h"
#import "NSManagedObjectContext+QMMagicalRecord.h"
#include <libkern/OSAtomic.h>

static NSString const * kQMMagicalRecordManagedObjectContextKey = @"QMMagicalRecord_NSManagedObjectContextForThreadKey";
static NSString const * kQMMagicalRecordManagedObjectContextCacheVersionKey = @"QMMagicalRecord_CacheVersionOfNSManagedObjectContextForThreadKey";
static volatile int32_t contextsCacheVersion = 0;


@implementation NSManagedObjectContext (QMMagicalThreading)

+ (void)QM_resetContextForCurrentThread
{
    [[NSManagedObjectContext QM_contextForCurrentThread] reset];
}

+ (void) QM_clearNonMainThreadContextsCache
{
	OSAtomicIncrement32(&contextsCacheVersion);
}

+ (NSManagedObjectContext *) QM_contextForCurrentThread;
{
	if ([NSThread isMainThread])
	{
		return [self QM_defaultContext];
	}
	else
	{
		// contextsCacheVersion can change (atomically) at any time, so grab a copy to ensure that we always
		// use the same value throughout the remainder of this method. We are OK with this method returning
		// an outdated context if QM_clearNonMainThreadContextsCache is called from another thread while this
		// method is being executed. This behavior is unrelated to our choice to use a counter for synchronization.
		// We would have the same behavior if we used @synchronized() (or any other lock-based synchronization
		// method) since QM_clearNonMainThreadContextsCache would have to wait until this method finished before
		// it could acquire the mutex, resulting in us still returning an outdated context in that case as well.
		int32_t targetCacheVersionForContext = contextsCacheVersion;

		NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
		NSManagedObjectContext *threadContext = [threadDict objectForKey:kQMMagicalRecordManagedObjectContextKey];
		NSNumber *currentCacheVersionForContext = [threadDict objectForKey:kQMMagicalRecordManagedObjectContextCacheVersionKey];
		NSAssert((threadContext && currentCacheVersionForContext) || (!threadContext && !currentCacheVersionForContext),
                 @"The QMMagical Record keys should either both be present or neither be present, otherwise we're in an inconsistent state!");
		if ((threadContext == nil) || (currentCacheVersionForContext == nil) || ((int32_t)[currentCacheVersionForContext integerValue] != targetCacheVersionForContext))
		{
			threadContext = [self QM_contextWithParent:[NSManagedObjectContext QM_defaultContext]];
			[threadDict setObject:threadContext forKey:kQMMagicalRecordManagedObjectContextKey];
			[threadDict setObject:[NSNumber numberWithInteger:targetCacheVersionForContext]
                           forKey:kQMMagicalRecordManagedObjectContextCacheVersionKey];
		}
		return threadContext;
	}
}

+ (void) QM_clearContextForCurrentThread {
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:kQMMagicalRecordManagedObjectContextKey];
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:kQMMagicalRecordManagedObjectContextCacheVersionKey];
}

@end
