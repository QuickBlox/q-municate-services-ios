//
//  QMContactListCache.m
//  QMServices
//
//  Created by Andrey on 06.11.14.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//

#import "QMContactListCache.h"
#import "QMCLModelIncludes.h"
#import "CDContactListItem.h"
#import "CDUser.h"

#import "QMSLog.h"

@implementation QMContactListCache

static QMContactListCache *_chatCacheInstance = nil;

#pragma mark - Singleton

+ (QMContactListCache *)instance {
    
    NSAssert(_chatCacheInstance, @"You must first perform @selector(setupDBWithStoreNamed:)");
    return _chatCacheInstance;
}

#pragma mark - Configure store

+ (void)setupDBWithStoreNamed:(NSString *)storeName {
    
    [self setupDBWithStoreNamed:storeName
     applicationGroupIdentifier:nil];
}

+ (void)setupDBWithStoreNamed:(NSString *)storeName
   applicationGroupIdentifier:(NSString *)appGroupIdentifier {
    
    NSManagedObjectModel *model =
    [NSManagedObjectModel QM_newModelNamed:@"QMContactListModel.momd"
                             inBundleNamed:@"QMContactListCacheModel.bundle"
                                 fromClass:[self class]];
    
    _chatCacheInstance =
    [[QMContactListCache alloc] initWithStoreNamed:storeName
                                             model:model
                        applicationGroupIdentifier:appGroupIdentifier];
}

+ (void)cleanDBWithStoreName:(NSString *)name {
    
    if (_chatCacheInstance) {
        _chatCacheInstance = nil;
    }
    
    [super cleanDBWithStoreName:name];
}

#pragma mark Dialogs
#pragma mark Insert / Update / Delete contact items

- (void)insertOrUpdateContactListItem:(QBContactListItem *)contactListItem
                           completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        CDContactListItem *item =
        [CDContactListItem QM_findFirstOrCreateByAttribute:@"userID"
                                                 withValue:@(contactListItem.userID)
                                                 inContext:ctx];
        
        [item updateWithQBContactListItem:contactListItem];
        
        QMSLog(@"[%@] ContactListItems to insert %tu, update %tu", NSStringFromClass([self class]),
               ctx.insertedObjects.count,
               ctx.updatedObjects.count);
        
    } finish:completion];
}

- (void)insertOrUpdateContactListWithItems:(NSArray<QBContactListItem *> *)contactListItems
                                completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        for (QBContactListItem *contactListItem in contactListItems) {
            
            CDContactListItem *item =
            [CDContactListItem QM_findFirstOrCreateByAttribute:@"userID"
                                                     withValue:@(contactListItem.userID)
                                                     inContext:ctx];
            
            [item updateWithQBContactListItem:contactListItem];
        }
        
        QMSLog(@"[%@] ContactListItems to insert %tu, update %tu", NSStringFromClass([self class]),
               ctx.insertedObjects.count,
               ctx.updatedObjects.count);
        
    } finish:completion];
}

- (void)insertOrUpdateContactListItemsWithContactList:(QBContactList *)contactList
                                           completion:(dispatch_block_t)completion {
    NSMutableArray *items =
    [NSMutableArray arrayWithCapacity:contactList.contacts.count + contactList.pendingApproval.count];
    
    [items addObjectsFromArray:contactList.contacts];
    [items addObjectsFromArray:contactList.pendingApproval];
    
    [self insertOrUpdateContactListWithItems:[items copy]
                                  completion:completion];
}

- (void)deleteContactListItem:(QBContactListItem *)contactListItem
                   completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        [CDContactListItem QM_deleteAllMatchingPredicate:IS(@"userID", @(contactListItem.userID))
                                               inContext:ctx];
    } finish:completion];
}

- (void)deleteContactList:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        [CDContactListItem QM_truncateAllInContext:ctx];
    } finish:completion];
}

- (void)contactListItems:(void(^)(NSArray<QBContactListItem *> *contactListItems))completion {
    
    [self performMainQueue:^(NSManagedObjectContext *ctx) {
        
        NSArray<CDContactListItem *> *cached = [CDContactListItem QM_findAllInContext:ctx];
        completion([cached toQBContactListItems]);
    }];
}

- (void)contactListItemWithUserID:(NSUInteger)userID completion:(void(^)(QBContactListItem *))completion {
    
    [self performMainQueue:^(NSManagedObjectContext *ctx) {
        
        CDContactListItem *cachedContactListItem =
        [CDContactListItem QM_findFirstWithPredicate:IS(@"userID", @(userID))
                                           inContext:ctx];
        QBContactListItem *item = [cachedContactListItem toQBContactListItem];
        completion(item);
    }];
}

@end
