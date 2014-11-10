//
//  NSPersistentStoreCoordinator+QMMagicalRecord.m
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 QMMagical Panda Software, LLC All rights reserved.
//

#import "CoreData+QMMagicalRecord.h"
#import "QMMagicalRecordLogging.h"

static NSPersistentStoreCoordinator *defaultCoordinator_ = nil;
NSString * const kQMMagicalRecordPSCDidCompleteiCloudSetupNotification = @"kQMMagicalRecordPSCDidCompleteiCloudSetupNotification";
NSString * const kQMMagicalRecordPSCMismatchWillDeleteStore = @"kQMMagicalRecordPSCMismatchWillDeleteStore";
NSString * const kQMMagicalRecordPSCMismatchDidDeleteStore = @"kQMMagicalRecordPSCMismatchDidDeleteStore";
NSString * const kQMMagicalRecordPSCMismatchWillRecreateStore = @"kQMMagicalRecordPSCMismatchWillRecreateStore";
NSString * const kQMMagicalRecordPSCMismatchDidRecreateStore = @"kQMMagicalRecordPSCMismatchDidRecreateStore";
NSString * const kQMMagicalRecordPSCMismatchCouldNotDeleteStore = @"kQMMagicalRecordPSCMismatchCouldNotDeleteStore";
NSString * const kQMMagicalRecordPSCMismatchCouldNotRecreateStore = @"kQMMagicalRecordPSCMismatchCouldNotRecreateStore";

@interface NSDictionary (QMMagicalRecordMerging)

- (NSMutableDictionary*) QM_dictionaryByMergingDictionary:(NSDictionary*)d; 

@end 

@interface QMMagicalRecord (iCloudPrivate)

+ (void) setICloudEnabled:(BOOL)enabled;

@end

@implementation NSPersistentStoreCoordinator (QMMagicalRecord)

+ (NSPersistentStoreCoordinator *) QM_defaultStoreCoordinator
{
    if (defaultCoordinator_ == nil && [QMMagicalRecord shouldAutoCreateDefaultPersistentStoreCoordinator])
    {
        [self QM_setDefaultStoreCoordinator:[self QM_newPersistentStoreCoordinator]];
    }
	return defaultCoordinator_;
}

+ (void) QM_setDefaultStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	defaultCoordinator_ = coordinator;
    
    if (defaultCoordinator_ != nil)
    {
        NSArray *persistentStores = [defaultCoordinator_ persistentStores];
        
        if ([persistentStores count] && [NSPersistentStore QM_defaultPersistentStore] == nil)
        {
            [NSPersistentStore QM_setDefaultPersistentStore:[persistentStores firstObject]];
        }
    }
}

- (void) QM_createPathToStoreFileIfNeccessary:(NSURL *)urlForStore
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *pathToStore = [urlForStore URLByDeletingLastPathComponent];
    
    NSError *error = nil;
    BOOL pathWasCreated = [fileManager createDirectoryAtPath:[pathToStore path] withIntermediateDirectories:YES attributes:nil error:&error];

    if (!pathWasCreated) 
    {
        [QMMagicalRecord handleErrors:error];
    }
}

- (NSPersistentStore *) QM_addSqliteStoreNamed:(id)storeFileName withOptions:(__autoreleasing NSDictionary *)options
{
    NSURL *url = [storeFileName isKindOfClass:[NSURL class]] ? storeFileName : [NSPersistentStore QM_urlForStoreName:storeFileName];
    NSError *error = nil;
    
    [self QM_createPathToStoreFileIfNeccessary:url];
    
    NSPersistentStore *store = [self addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:url
                                                        options:options
                                                          error:&error];
    
    if (!store) 
    {
        if ([QMMagicalRecord shouldDeleteStoreOnModelMismatch])
        {
            BOOL isMigrationError = (([error code] == NSPersistentStoreIncompatibleVersionHashError) || ([error code] == NSMigrationMissingSourceModelError) || ([error code] == NSMigrationError));
            if ([[error domain] isEqualToString:NSCocoaErrorDomain] && isMigrationError)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kQMMagicalRecordPSCMismatchWillDeleteStore object:nil];
                
                NSError * deleteStoreError;
                // Could not open the database, so... kill it! (AND WAL bits)
                NSString *rawURL = [url absoluteString];
                NSURL *shmSidecar = [NSURL URLWithString:[rawURL stringByAppendingString:@"-shm"]];
                NSURL *walSidecar = [NSURL URLWithString:[rawURL stringByAppendingString:@"-wal"]];
                [[NSFileManager defaultManager] removeItemAtURL:url error:&deleteStoreError];
                [[NSFileManager defaultManager] removeItemAtURL:shmSidecar error:nil];
                [[NSFileManager defaultManager] removeItemAtURL:walSidecar error:nil];

                QMMRLogWarn(@"Removed incompatible model version: %@", [url lastPathComponent]);
                if(deleteStoreError) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kQMMagicalRecordPSCMismatchCouldNotDeleteStore object:nil userInfo:@{@"Error":deleteStoreError}];
                }
                else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kQMMagicalRecordPSCMismatchDidDeleteStore object:nil];
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kQMMagicalRecordPSCMismatchWillRecreateStore object:nil];
                // Try one more time to create the store
                store = [self addPersistentStoreWithType:NSSQLiteStoreType
                                           configuration:nil
                                                     URL:url
                                                 options:options
                                                   error:&error];
                if (store)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kQMMagicalRecordPSCMismatchDidRecreateStore object:nil];
                    // If we successfully added a store, remove the error that was initially created
                    error = nil;
                }
                else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kQMMagicalRecordPSCMismatchCouldNotRecreateStore object:nil userInfo:@{@"Error":error}];
                }
            }
        }
        [QMMagicalRecord handleErrors:error];
    }
    return store;
}

- (void) QM_addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey storeIdentifier:(id)storeIdentifier cloudStorePathComponent:(NSString *)subPathComponent completion:(void(^)(void))completionBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSURL *cloudURL = [NSPersistentStore QM_cloudURLForUbiqutiousContainer:containerID];
        if (subPathComponent)
        {
            cloudURL = [cloudURL URLByAppendingPathComponent:subPathComponent];
        }
        
        [QMMagicalRecord setICloudEnabled:cloudURL != nil];
        
        NSDictionary *options = [[self class] QM_autoMigrationOptions];
        if (cloudURL)   //iCloud is available
        {
            NSDictionary *iCloudOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                           contentNameKey, NSPersistentStoreUbiquitousContentNameKey,
                                           cloudURL, NSPersistentStoreUbiquitousContentURLKey, nil];
            options = [options QM_dictionaryByMergingDictionary:iCloudOptions];
        }
        else
        {
            QMMRLogWarn(@"iCloud is not enabled");
        }


        if ([self respondsToSelector:@selector(performBlockAndWait:)])
        {
            [self performSelector:@selector(performBlockAndWait:) withObject:^{
                [self QM_addSqliteStoreNamed:storeIdentifier withOptions:options];
            }];
        }
        else
        {
            [self lock];
            [self QM_addSqliteStoreNamed:storeIdentifier withOptions:options];
            [self unlock];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if ([NSPersistentStore QM_defaultPersistentStore] == nil)
            {
                [NSPersistentStore QM_setDefaultPersistentStore:[[self persistentStores] firstObject]];
            }
            if (completionBlock)
            {
                completionBlock();
            }
            NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
            [notificationCenter postNotificationName:kQMMagicalRecordPSCDidCompleteiCloudSetupNotification object:nil];
        });
    });
}



#pragma mark - Public Instance Methods

- (NSPersistentStore *) QM_addInMemoryStore
{
    NSError *error = nil;
    NSPersistentStore *store = [self addPersistentStoreWithType:NSInMemoryStoreType
                                                  configuration:nil 
                                                            URL:nil
                                                        options:nil
                                                          error:&error];
    if (!store)
    {
        [QMMagicalRecord handleErrors:error];
    }
    return store;
}

+ (NSDictionary *) QM_autoMigrationOptions;
{
    // Adding the journalling mode recommended by apple
    NSMutableDictionary *sqliteOptions = [NSMutableDictionary dictionary];
    [sqliteOptions setObject:@"WAL" forKey:@"journal_mode"];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             sqliteOptions, NSSQLitePragmasOption,
                             nil];
    return options;
}

- (NSPersistentStore *) QM_addAutoMigratingSqliteStoreNamed:(NSString *) storeFileName;
{
    NSDictionary *options = [[self class] QM_autoMigrationOptions];
    return [self QM_addSqliteStoreNamed:storeFileName withOptions:options];
}

- (NSPersistentStore *) QM_addAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL
{
    NSDictionary *options = [[self class] QM_autoMigrationOptions];
    return [self QM_addSqliteStoreNamed:storeURL withOptions:options];
}


#pragma mark - Public Class Methods


+ (NSPersistentStoreCoordinator *) QM_coordinatorWithAutoMigratingSqliteStoreNamed:(NSString *) storeFileName
{
    NSManagedObjectModel *model = [NSManagedObjectModel QM_defaultManagedObjectModel];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [coordinator QM_addAutoMigratingSqliteStoreNamed:storeFileName];
    
    //HACK: lame solution to fix automigration error "Migration failed after first pass"
    if ([[coordinator persistentStores] count] == 0) 
    {
        [coordinator performSelector:@selector(QM_addAutoMigratingSqliteStoreNamed:) withObject:storeFileName afterDelay:0.5];
    }

    return coordinator;
}

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL
{
    NSManagedObjectModel *model = [NSManagedObjectModel QM_defaultManagedObjectModel];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [coordinator QM_addAutoMigratingSqliteStoreAtURL:storeURL];
    
    //HACK: lame solution to fix automigration error "Migration failed after first pass"
    if ([[coordinator persistentStores] count] == 0)
    {
        [coordinator performSelector:@selector(QM_addAutoMigratingSqliteStoreAtURL:) withObject:storeURL afterDelay:0.5];
    }
    
    return coordinator;
}

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithInMemoryStore
{
	NSManagedObjectModel *model = [NSManagedObjectModel QM_defaultManagedObjectModel];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

    [coordinator QM_addInMemoryStore];

    return coordinator;
}

+ (NSPersistentStoreCoordinator *) QM_newPersistentStoreCoordinator
{
	NSPersistentStoreCoordinator *coordinator = [self QM_coordinatorWithSqliteStoreNamed:[QMMagicalRecord defaultStoreName]];

    return coordinator;
}

- (void) QM_addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)subPathComponent;
{
    [self QM_addiCloudContainerID:containerID 
                   contentNameKey:contentNameKey 
                  localStoreNamed:localStoreName
          cloudStorePathComponent:subPathComponent
                       completion:nil];
}

- (void) QM_addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreAtURL:(NSURL *)storeURL cloudStorePathComponent:(NSString *)subPathComponent
{
    [self QM_addiCloudContainerID:containerID
                   contentNameKey:contentNameKey
                  localStoreAtURL:storeURL
          cloudStorePathComponent:subPathComponent
                       completion:nil];
}

- (void) QM_addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)subPathComponent completion:(void(^)(void))completionBlock;
{
    [self QM_addiCloudContainerID:containerID
                   contentNameKey:contentNameKey
                  storeIdentifier:localStoreName
          cloudStorePathComponent:subPathComponent
                       completion:completionBlock]; 
}

- (void) QM_addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreAtURL:(NSURL *)storeURL cloudStorePathComponent:(NSString *)subPathComponent completion:(void(^)(void))completionBlock;
{
    [self QM_addiCloudContainerID:containerID
                   contentNameKey:contentNameKey
                  storeIdentifier:storeURL
          cloudStorePathComponent:subPathComponent
                       completion:completionBlock];   
}

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithiCloudContainerID:(NSString *)containerID 
                                                        contentNameKey:(NSString *)contentNameKey
                                                       localStoreNamed:(NSString *)localStoreName
                                               cloudStorePathComponent:(NSString *)subPathComponent;
{
    return [self QM_coordinatorWithiCloudContainerID:containerID 
                                      contentNameKey:contentNameKey
                                     localStoreNamed:localStoreName
                             cloudStorePathComponent:subPathComponent
                                          completion:nil];
}

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithiCloudContainerID:(NSString *)containerID
                                                        contentNameKey:(NSString *)contentNameKey
                                                       localStoreAtURL:(NSURL *)storeURL
                                               cloudStorePathComponent:(NSString *)subPathComponent
{
    return [self QM_coordinatorWithiCloudContainerID:containerID
                               contentNameKey:contentNameKey
                              localStoreAtURL:storeURL
                      cloudStorePathComponent:subPathComponent
                                   completion:nil];
}

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithiCloudContainerID:(NSString *)containerID 
                                                        contentNameKey:(NSString *)contentNameKey
                                                       localStoreNamed:(NSString *)localStoreName
                                               cloudStorePathComponent:(NSString *)subPathComponent
                                                            completion:(void(^)(void))completionHandler;
{
    NSManagedObjectModel *model = [NSManagedObjectModel QM_defaultManagedObjectModel];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [psc QM_addiCloudContainerID:containerID 
                  contentNameKey:contentNameKey
                 localStoreNamed:localStoreName
         cloudStorePathComponent:subPathComponent
                      completion:completionHandler];
    
    return psc;
}

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithiCloudContainerID:(NSString *)containerID
                                                        contentNameKey:(NSString *)contentNameKey
                                                       localStoreAtURL:(NSURL *)storeURL
                                               cloudStorePathComponent:(NSString *)subPathComponent
                                                            completion:(void (^)(void))completionHandler
{
    NSManagedObjectModel *model = [NSManagedObjectModel QM_defaultManagedObjectModel];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [psc QM_addiCloudContainerID:containerID
                  contentNameKey:contentNameKey
                 localStoreAtURL:storeURL
         cloudStorePathComponent:subPathComponent
                      completion:completionHandler];
    
    return psc;
}

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithPersistentStore:(NSPersistentStore *)persistentStore;
{
    NSManagedObjectModel *model = [NSManagedObjectModel QM_defaultManagedObjectModel];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [psc QM_addSqliteStoreNamed:[persistentStore URL] withOptions:nil];

    return psc;
}

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithSqliteStoreNamed:(NSString *)storeFileName withOptions:(NSDictionary *)options
{
    NSManagedObjectModel *model = [NSManagedObjectModel QM_defaultManagedObjectModel];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [psc QM_addSqliteStoreNamed:storeFileName withOptions:options];
    return psc;
}

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithSqliteStoreAtURL:(NSURL *)storeURL withOptions:(NSDictionary *)options
{
    NSManagedObjectModel *model = [NSManagedObjectModel QM_defaultManagedObjectModel];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    [psc QM_addSqliteStoreNamed:storeURL withOptions:options];
    return psc;
}

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithSqliteStoreNamed:(NSString *)storeFileName
{
	return [self QM_coordinatorWithSqliteStoreNamed:storeFileName withOptions:nil];
}

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithSqliteStoreAtURL:(NSURL *)storeURL
{
    return [self QM_coordinatorWithSqliteStoreAtURL:storeURL withOptions:nil];
}

@end


@implementation NSDictionary (Merging) 

- (NSMutableDictionary *) QM_dictionaryByMergingDictionary:(NSDictionary *)d;
{
    NSMutableDictionary *mutDict = [self mutableCopy];
    [mutDict addEntriesFromDictionary:d];
    return mutDict; 
} 

@end 
