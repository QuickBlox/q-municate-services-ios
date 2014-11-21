//
//  QMContactListCache.h
//  QMContactListCache
//
//  Created by Andrey Ivanov on 06.11.14.
//
//

#import <Foundation/Foundation.h>
#import "QMDBStorage.h"

@interface QMContactListCache : QMDBStorage

#pragma mark - Singleton

/**
 *  Chat cache singleton
 *
 *  @return QMContactListCache instance
 */
+ (QMContactListCache *)instance;

#pragma mark - Configure store

/**
 *  Setup QMContactListCache stake wit store name
 *
 *  @param storeName Store name
 */
+ (void)setupDBWithStoreNamed:(NSString *)storeName;

/**
 *  Clean clean chat cache with store name
 *
 *  @param name Store name
 */
+ (void)cleanDBWithStoreName:(NSString *)name;

- (void)cacheQBUsers:(NSArray *)users finish:(void(^)(void))finish;
- (void)cachedQBUsers:(void(^)(NSArray *array))users;

- (void)cacheQBContactListItems:(NSArray *)contactListItems finish:(void(^)(void))finish;
- (void)cachedQBContactListItems:(void(^)(NSArray *array))contactListItems;

@end
