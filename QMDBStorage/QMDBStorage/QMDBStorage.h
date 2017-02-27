//
//  QMDBStorage.h
//  QMDBStorage
//
//  Created by Andrey Ivanov on 06.11.14.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IS(attrName, attrVal) [NSPredicate predicateWithFormat:@"%K == %@", attrName, attrVal]

#import "QMCDRecord.h"

@interface QMDBStorage : NSObject

@property (strong, nonatomic, readonly) NSManagedObjectContext *mainQueueContext;

- (instancetype)initWithStoreNamed:(NSString *)storeName
                             model:(NSManagedObjectModel *)model
                        queueLabel:(const char *)queueLabel
        applicationGroupIdentifier:(NSString *)appGroupIdentifier;

- (instancetype)initWithStoreNamed:(NSString *)storeName
                             model:(NSManagedObjectModel *)model
                        queueLabel:(const char *)queueLabel;
/**
 * @brief Load CoreData(Sqlite) file
 * @param name - filename
 */
+ (void)setupDBWithStoreNamed:(NSString *)storeName;

+ (void)setupDBWithStoreNamed:(NSString *)storeName
   applicationGroupIdentifier:(nullable NSString *)appGroupIdentifier;

/**
 * @brief Clean data base with store name
 */
+ (void)cleanDBWithStoreName:(NSString *)name;

- (void)perfomBackgroundQueue:(void (^)(NSManagedObjectContext *ctx))block;

- (void)save:(void (^)(NSManagedObjectContext *ctx))block
      finish:(dispatch_block_t)finish;

@end
