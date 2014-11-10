//
//  NSPersistentStoreCoordinator+QMMagicalRecord.h
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 QMMagical Panda Software, LLC All rights reserved.
//

#import "QMMagicalRecord.h"
#import "NSPersistentStore+QMMagicalRecord.h"

extern NSString * const kQMMagicalRecordPSCDidCompleteiCloudSetupNotification;
extern NSString * const kQMMagicalRecordPSCMismatchWillDeleteStore;
extern NSString * const kQMMagicalRecordPSCMismatchDidDeleteStore;
extern NSString * const kQMMagicalRecordPSCMismatchWillRecreateStore;
extern NSString * const kQMMagicalRecordPSCMismatchDidRecreateStore;
extern NSString * const kQMMagicalRecordPSCMismatchCouldNotDeleteStore;
extern NSString * const kQMMagicalRecordPSCMismatchCouldNotRecreateStore;

@interface NSPersistentStoreCoordinator (QMMagicalRecord)

+ (NSPersistentStoreCoordinator *) QM_defaultStoreCoordinator;
+ (void) QM_setDefaultStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator;

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithInMemoryStore;

+ (NSPersistentStoreCoordinator *) QM_newPersistentStoreCoordinator NS_RETURNS_RETAINED;

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithSqliteStoreNamed:(NSString *)storeFileName;
+ (NSPersistentStoreCoordinator *) QM_coordinatorWithAutoMigratingSqliteStoreNamed:(NSString *)storeFileName;
+ (NSPersistentStoreCoordinator *) QM_coordinatorWithSqliteStoreAtURL:(NSURL *)storeURL;
+ (NSPersistentStoreCoordinator *) QM_coordinatorWithAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL;
+ (NSPersistentStoreCoordinator *) QM_coordinatorWithPersistentStore:(NSPersistentStore *)persistentStore;
+ (NSPersistentStoreCoordinator *) QM_coordinatorWithiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)subPathComponent;
+ (NSPersistentStoreCoordinator *) QM_coordinatorWithiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreAtURL:(NSURL *)storeURL cloudStorePathComponent:(NSString *)subPathComponent;

+ (NSPersistentStoreCoordinator *) QM_coordinatorWithiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)subPathComponent completion:(void(^)(void))completionHandler;
+ (NSPersistentStoreCoordinator *) QM_coordinatorWithiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreAtURL:(NSURL *)storeURL cloudStorePathComponent:(NSString *)subPathComponent completion:(void (^)(void))completionHandler;

- (NSPersistentStore *) QM_addInMemoryStore;
- (NSPersistentStore *) QM_addAutoMigratingSqliteStoreNamed:(NSString *) storeFileName;
- (NSPersistentStore *) QM_addAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL;

- (NSPersistentStore *) QM_addSqliteStoreNamed:(id)storeFileName withOptions:(__autoreleasing NSDictionary *)options;

- (void) QM_addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)subPathComponent;
- (void) QM_addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreAtURL:(NSURL *)storeURL cloudStorePathComponent:(NSString *)subPathComponent;
- (void) QM_addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)subPathComponent completion:(void(^)(void))completionBlock;
- (void) QM_addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreAtURL:(NSURL *)storeURL cloudStorePathComponent:(NSString *)subPathComponent completion:(void (^)(void))completionBlock;

@end
