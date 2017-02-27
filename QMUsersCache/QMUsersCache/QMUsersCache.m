//
//  QMUsersCache.m
//  QMUsersCache
//
//  Created by Andrey Moskvin on 10/23/15.
//  Copyright © 2015 Quickblox. All rights reserved.
//

#import "QMUsersCache.h"
#import "QMUsersModelIncludes.h"

#import "QMSLog.h"

@implementation QMUsersCache

static QMUsersCache *_usersCacheInstance = nil;

#pragma mark - Singleton

+ (QMUsersCache *)instance
{
    NSAssert(_usersCacheInstance, @"You must first perform @selector(setupDBWithStoreNamed:)");
    return _usersCacheInstance;
}

#pragma mark - Configure store

+ (void)setupDBWithStoreNamed:(NSString *)storeName
   applicationGroupIdentifier:(NSString *)appGroupIdentifier {
    
    NSManagedObjectModel *model =
    [NSManagedObjectModel QM_newModelNamed:@"QMUsersModel.momd"
                             inBundleNamed:@"QMUsersCacheModel.bundle"
                                 fromClass:[self class]];
    
    NSParameterAssert(!_usersCacheInstance);
    _usersCacheInstance =
    [[QMUsersCache alloc] initWithStoreNamed:storeName
                                       model:model
                                  queueLabel:"com.qmservices.QMUsersCacheQueue"
                  applicationGroupIdentifier:appGroupIdentifier];
}

+ (void)setupDBWithStoreNamed:(NSString *)storeName {
    
    return [self setupDBWithStoreNamed:storeName
            applicationGroupIdentifier:nil];
}

+ (void)cleanDBWithStoreName:(NSString *)name {
    
    if (_usersCacheInstance) {
        _usersCacheInstance = nil;
    }
    [super cleanDBWithStoreName:name];
}

#pragma mark - Users

- (BFTask *)insertOrUpdateUser:(QBUUser *)user {
    
    return [self insertOrUpdateUsers:@[user]];
}

- (BFTask *)insertOrUpdateUsers:(NSArray *)users {
    
    BFTaskCompletionSource *source =
    [BFTaskCompletionSource taskCompletionSource];
    
    [self save:^(NSManagedObjectContext *ctx) {
        //To Insert / Update
        for (QBUUser *user in users) {
            
            CDUser *cachedUser =
            [CDUser QM_findFirstOrCreateByAttribute:@"id"
                                          withValue:@(user.ID)
                                          inContext:ctx];
            
            [cachedUser updateWithQBUser:user];
        }
        
        QMSLog(@"[%@] Users to insert %tu, update %tu",
               NSStringFromClass([QMUsersCache class]),
               ctx.insertedObjects.count,
               ctx.updatedObjects.count);
        
    } finish:^{
        [source setResult:nil];
    }];
    
    return source.task;
}

- (BFTask *)deleteUser:(QBUUser *)user {
    
    BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        [CDUser QM_deleteAllMatchingPredicate:IS(@"id", @(user.ID))
                                    inContext:ctx];
    } finish:^{
        
        [source setResult:nil];
    }];
    
    return source.task;
}

- (BFTask *)deleteAllUsers {
    
    BFTaskCompletionSource *source =
    [BFTaskCompletionSource taskCompletionSource];
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        [CDUser QM_truncateAllInContext:ctx];
        
    } finish:^{
        
        [source setResult:nil];
    }];
    
    return source.task;
}

- (BFTask *)userWithPredicate:(NSPredicate *)predicate {
    
    BFTaskCompletionSource *source =
    [BFTaskCompletionSource taskCompletionSource];
    
    [self perfomBackgroundQueue:^(NSManagedObjectContext *ctx) {
        
        CDUser *user = [CDUser QM_findFirstWithPredicate:predicate
                                                   inContext:ctx];
        [source setResult:[user toQBUUser]];
    }];
    
    return source.task;
}

- (BFTask *)usersSortedBy:(NSString *)sortTerm
                ascending:(BOOL)ascending {
    
    return [self usersWithPredicate:nil
                           sortedBy:sortTerm
                          ascending:ascending];
}

- (NSArray <QBUUser*> *)allUsers {

    NSArray<CDUser *> *users =
    [CDUser QM_findAllInContext:self.mainQueueContext];
    
    NSArray<QBUUser *> *result =
    [self convertCDUsertsToQBUsers:users];
    
    return result;
}

- (BFTask *)usersWithPredicate:(NSPredicate *)predicate
                      sortedBy:(NSString *)sortTerm
                     ascending:(BOOL)ascending {
    
    BFTaskCompletionSource *source =
    [BFTaskCompletionSource taskCompletionSource];
    
    [self perfomBackgroundQueue:^(NSManagedObjectContext *ctx) {
        
        NSArray<CDUser *> *users =
        [CDUser QM_findAllSortedBy:sortTerm
                         ascending:ascending
                     withPredicate:predicate
                         inContext:ctx];
        
        NSArray<QBUUser *> *result =
        [self convertCDUsertsToQBUsers:users];
        
        [source setResult:result];
    }];
    
    return source.task;
}

- (NSArray<QBUUser *> *)convertCDUsertsToQBUsers:(NSArray *)cdUsers {
    
    NSMutableArray<QBUUser *> *users =
    [NSMutableArray arrayWithCapacity:cdUsers.count];
    
    for (CDUser *user in cdUsers) {
        
        QBUUser *qbUser = [user toQBUUser];
        [users addObject:qbUser];
    }
    
    return users;
}

@end
