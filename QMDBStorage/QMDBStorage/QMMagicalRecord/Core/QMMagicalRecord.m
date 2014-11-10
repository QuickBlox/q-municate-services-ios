//
//  QMMagicalRecord.m
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 QMMagical Panda Software, LLC All rights reserved.
//

#import "CoreData+QMMagicalRecord.h"

NSString * const kQMMagicalRecordCleanedUpNotification = @"kQMMagicalRecordCleanedUpNotification";

@interface QMMagicalRecord (Internal)

+ (void) cleanUpStack;
+ (void) cleanUpErrorHanding;

@end

@interface NSManagedObjectContext (QMMagicalRecordInternal)

+ (void) QM_cleanUp;

@end


@implementation QMMagicalRecord

+ (QMMagicalRecordVersionNumber) version
{
    return QMMagicalRecordVersionNumber2_3;
}

+ (void) cleanUp
{
    [self cleanUpErrorHanding];
    [self cleanUpStack];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:kQMMagicalRecordCleanedUpNotification
                                      object:nil
                                    userInfo:nil];
}

+ (void) cleanUpStack;
{
	[NSManagedObjectContext QM_cleanUp];
	[NSManagedObjectModel QM_setDefaultManagedObjectModel:nil];
	[NSPersistentStoreCoordinator QM_setDefaultStoreCoordinator:nil];
	[NSPersistentStore QM_setDefaultPersistentStore:nil];
}

+ (NSString *) currentStack
{
    NSMutableString *status = [NSMutableString stringWithString:@"Current Default Core Data Stack: ---- \n"];

    [status appendFormat:@"Model:           %@\n", [[NSManagedObjectModel QM_defaultManagedObjectModel] entityVersionHashesByName]];
    [status appendFormat:@"Coordinator:     %@\n", [NSPersistentStoreCoordinator QM_defaultStoreCoordinator]];
    [status appendFormat:@"Store:           %@\n", [NSPersistentStore QM_defaultPersistentStore]];
    [status appendFormat:@"Default Context: %@\n", [[NSManagedObjectContext QM_defaultContext] QM_description]];
    [status appendFormat:@"Context Chain:   \n%@\n", [[NSManagedObjectContext QM_defaultContext] QM_parentChain]];

    return status;
}

+ (void) setDefaultModelNamed:(NSString *)modelName;
{
    NSManagedObjectModel *model = [NSManagedObjectModel QM_managedObjectModelNamed:modelName];
    [NSManagedObjectModel QM_setDefaultManagedObjectModel:model];
}

+ (void) setDefaultModelFromClass:(Class)modelClass;
{
    NSBundle *bundle = [NSBundle bundleForClass:modelClass];
    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];
    [NSManagedObjectModel QM_setDefaultManagedObjectModel:model];
}

+ (NSString *) defaultStoreName;
{
    NSString *defaultName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(id)kCFBundleNameKey];
    if (defaultName == nil)
    {
        defaultName = kQMMagicalRecordDefaultStoreFileName;
    }
    if (![defaultName hasSuffix:@"sqlite"]) 
    {
        defaultName = [defaultName stringByAppendingPathExtension:@"sqlite"];
    }

    return defaultName;
}


#pragma mark - initialize

+ (void) initialize;
{
    if (self == [QMMagicalRecord class]) 
    {
#ifdef QM_SHORTHAND
        [self swizzleShorthandMethods];
#endif
        [self setShouldAutoCreateManagedObjectModel:YES];
        [self setShouldAutoCreateDefaultPersistentStoreCoordinator:NO];
#ifdef DEBUG
        [self setShouldDeleteStoreOnModelMismatch:YES];
#else
        [self setShouldDeleteStoreOnModelMismatch:NO];
#endif
    }
}

@end


