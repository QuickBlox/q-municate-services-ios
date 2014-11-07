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

- (void)cacheQBUsers:(NSArray *)users finish:(void(^)(void))finish;
- (void)cachedQBUsers:(void(^)(NSArray *array))users;

- (void)cacheQBContactListItems:(NSArray *)contactListItems finish:(void(^)(void))finish;
- (void)cachedQBContactListItems:(void(^)(NSArray *array))contactListItems;

@end
