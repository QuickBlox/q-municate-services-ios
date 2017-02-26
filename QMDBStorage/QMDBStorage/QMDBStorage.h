//
//  QMDBStorage.h
//  QMDBStorage
//
//  Created by Andrey Ivanov on 06.11.14.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CONTAINS(attrName, attrVal) [NSPredicate predicateWithFormat:@"self.%K CONTAINS %@", attrName, attrVal]
#define LIKE(attrName, attrVal) [NSPredicate predicateWithFormat:@"%K like %@", attrName, attrVal]
#define LIKE_C(attrName, attrVal) [NSPredicate predicateWithFormat:@"%K like[c] %@", attrName, attrVal]
#define IS(attrName, attrVal) [NSPredicate predicateWithFormat:@"%K == %@", attrName, attrVal]

//#define DO_AT_MAIN(x) dispatch_async(dispatch_get_main_queue(), ^{ x; });

#import "QMCDRecord.h"

@interface QMDBStorage : NSObject

@property (strong, nonatomic, readonly) QMCDRecordStack *stack;
@property (strong, nonatomic, readonly) NSManagedObjectContext *context;

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

+ (void)setupDBWithStoreNamed:(NSString *)storeName ;

+ (void)setupDBWithStoreNamed:(NSString *)storeName
   applicationGroupIdentifier:(nullable NSString *)appGroupIdentifier;

/**
 * @brief Clean data base with store name
 */

+ (void)cleanDBWithStoreName:(NSString *)name;

- (void)saveContext:(void (^)(NSManagedObjectContext *ctx))context
               save:(dispatch_block_t)save;

@end
