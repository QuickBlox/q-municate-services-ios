//
//  QMUsersCache.h
//  QMUsersCache
//
//  Created by Andrey Moskvin on 10/23/15.
//  Copyright © 2015 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMDBStorage.h"

@interface QMUsersCache : QMDBStorage

+ (QMUsersCache *)instance;

#pragma mark - Insert/Update/Delete users in cache

- (BFTask *)insertOrUpdateUser:(QBUUser *)user;
- (BFTask *)insertOrUpdateUsers:(NSArray<QBUUser *> *)users;
- (BFTask *)deleteUser:(QBUUser *)user;
- (BFTask *)deleteAllUsers;

#pragma mark - Fetch users

- (BFTask<QBUUser *> *)userWithPredicate:(NSPredicate *) predicate;
- (BFTask<NSArray<QBUUser *> *> *)usersSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
- (BFTask<NSArray<QBUUser *> *> *)usersWithPredicate:(NSPredicate *)predicate
                                            sortedBy:(NSString *)sortTerm
                                           ascending:(BOOL)ascending;

@end
