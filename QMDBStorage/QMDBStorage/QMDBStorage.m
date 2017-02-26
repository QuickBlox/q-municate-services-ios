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

@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) QMCDRecordStack *stack;

@end

@implementation QMDBStorage


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
    }

    return self;
}


- (NSManagedObjectContext *)context {
    
    return self.stack.context;
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

+ (void)cleanDBWithStoreName:(NSString *)name applicationGroupIdentifier:(NSString *)appGroupIdentifier {
    
    NSURL *storeUrl = [NSPersistentStore QM_fileURLForStoreNameIfExistsOnDisk:name applicationGroupIdentifier:appGroupIdentifier];
    
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

- (void)saveContext:(void (^)(NSManagedObjectContext *ctx))context
               save:(dispatch_block_t)save {
    
    NSManagedObjectContext *privateContext =
    [NSManagedObjectContext QM_privateQueueContext];
    [privateContext setParentContext:self.stack.context];
    context(privateContext);
    [privateContext QM_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (save) save();
        });
    }];
}
@end
