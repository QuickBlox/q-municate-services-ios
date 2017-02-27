//
//  QMDBStorage.m
//  QMDBStorage
//
//  Created by Andrey on 06.11.14.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//

#import "QMDBStorage.h"

#import "QMSLog.h"
#import "QMCDRecord.h"

@interface QMDBStorage ()

#define QM_LOGGING_ENABLED 1

@property (strong, nonatomic) QMCDRecordStack *stack;

@property (strong, nonatomic) NSManagedObjectContext *saveContext;

@end

@implementation QMDBStorage

@dynamic mainQueueContext;

- (instancetype)initWithStoreNamed:(NSString *)storeName
                             model:(NSManagedObjectModel *)model
                        queueLabel:(const char *)queueLabel
        applicationGroupIdentifier:(NSString *)appGroupIdentifier {
    
    self = [super init];
    
    if (self) {
        
        _stack = [AutoMigratingQMCDRecordStack stackWithStoreNamed:storeName
                                                             model:model
                                        applicationGroupIdentifier:appGroupIdentifier];
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            [QMCDRecord setLoggingLevel:QMCDRecordLoggingLevelVerbose];
            
        });
        
        NSManagedObjectContext *general = [NSManagedObjectContext QM_privateQueueContext];
        [general setPersistentStoreCoordinator:self.stack.coordinator];
        
        self.stack.context = general;
        
        _saveContext = [NSManagedObjectContext QM_privateQueueContext];
        [_saveContext setParentContext:self.stack.context];
    }
    
    return self;
}

- (NSManagedObjectContext *)mainQueueContext {
    
    NSManagedObjectContext *mainContext =
    [NSManagedObjectContext QM_mainQueueContext];
    [mainContext setParentContext:self.stack.context];
    
    return mainContext;
}

- (void)perfomBackgroundQueue:(void (^)(NSManagedObjectContext *ctx))block {
    
    NSManagedObjectContext *backgroundContext =
    [NSManagedObjectContext QM_privateQueueContext];
    [backgroundContext setParentContext:self.stack.context];
    
    block(backgroundContext);
}

- (void)save:(void (^)(NSManagedObjectContext *ctx))block
      finish:(dispatch_block_t)finish {
    
    [_saveContext performBlock:^{
        
        if (block) block(_saveContext);
        [_saveContext QM_saveToPersistentStoreAndWait];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (finish) finish();
        });
    }];
}

- (instancetype)initWithStoreNamed:(NSString *)storeName
                             model:(NSManagedObjectModel *)model
                        queueLabel:(const char *)queueLabel {
    
    return [self initWithStoreNamed:storeName
                              model:model
                         queueLabel:queueLabel
         applicationGroupIdentifier:nil];
}

+ (void)setupDBWithStoreNamed:(NSString *)storeName {
    
    NSAssert(nil, @"must be overloaded");
}

+ (void)setupDBWithStoreNamed:(NSString *)storeName
   applicationGroupIdentifier:(nullable NSString *)appGroupIdentifier {
    NSAssert(nil, @"must be overloaded");
}

+ (void)cleanDBWithStoreName:(NSString *)name {
    
    [self cleanDBWithStoreName:name applicationGroupIdentifier:nil];
}

+ (void)cleanDBWithStoreName:(NSString *)name
  applicationGroupIdentifier:(NSString *)appGroupIdentifier {
    
    NSURL *storeUrl =
    [NSPersistentStore QM_fileURLForStoreNameIfExistsOnDisk:name
                                 applicationGroupIdentifier:appGroupIdentifier];
    
    if (storeUrl) {
        
        NSError *error = nil;
        if(![[NSFileManager defaultManager] removeItemAtURL:storeUrl error:&error]) {
            
            QMSLog(@"An error has occurred while deleting %@", storeUrl);
            QMSLog(@"Error description: %@", error.description);
        }
        else {
            
            QMSLog(@"Clear %@ - Done!", storeUrl);
        }
    }
}

@end
