//
//  QMChatCache.m
//  QMServices
//
//  Created by Andrey on 06.11.14.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//

#import "QMChatCache.h"
#import "QMCCModelIncludes.h"

#import "QMSLog.h"

@implementation QMChatCache

static QMChatCache *_chatCacheInstance = nil;

#pragma mark - Singleton

+ (QMChatCache *)instance {
    
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
    
    NSManagedObjectModel *model = [NSManagedObjectModel QM_newModelNamed:@"QMChatServiceModel.momd"
                                                           inBundleNamed:@"QMChatCacheModel.bundle"
                                                               fromClass:[self class]];
    
    _chatCacheInstance = [[QMChatCache alloc] initWithStoreNamed:storeName
                                                           model:model
                                                      queueLabel:"com.qmunicate.QMChatCacheBackgroundQueue"
                                      applicationGroupIdentifier:appGroupIdentifier];
}

+ (void)cleanDBWithStoreName:(NSString *)name {
    
    if (_chatCacheInstance) {
        _chatCacheInstance = nil;
    }
    
    [super cleanDBWithStoreName:name];
}

#pragma mark - Init

- (instancetype)init {
    
    self = [super init];
    
    if (self) {
        _messagesLimitPerDialog = NSNotFound;
    }
    
    return self;
}

#pragma mark -
#pragma mark Dialogs
#pragma mark -

- (NSArray *)dialogsFromCache:(NSArray *)cachedDialogs {
    
    NSMutableArray *qbChatDialogs = [NSMutableArray arrayWithCapacity:cachedDialogs.count];
    
    for (CDDialog *dialog in cachedDialogs) {
        
        QBChatDialog *result = [dialog toQBChatDialog];
        [qbChatDialogs addObject:result];
    }
    
    return qbChatDialogs;
}

#pragma mark Fetch Dialogs

- (void)allDialogsWithCompletion:(void(^)(NSArray<QBChatDialog *> *dialogs))completion {
    
    NSArray *cdChatDialogs = [CDDialog QM_findAllInContext:self.mainQueueContext];
    NSArray *allDialogs = [self dialogsFromCache:cdChatDialogs];
    
    completion(allDialogs);
}

- (void)dialogsSortedBy:(NSString *)sortTerm
              ascending:(BOOL)ascending
             completion:(void(^)(NSArray<QBChatDialog *> *dialogs))completion {
    
    [self dialogsSortedBy:sortTerm
                ascending:ascending
            withPredicate:nil
               completion:completion];
}

- (void)dialogByID:(NSString *)dialogID
        completion:(void (^)(QBChatDialog *cachedDialog))completion {
    
    CDDialog *dialog = [CDDialog QM_findFirstByAttribute:@"dialogID"
                                               withValue:dialogID
                                               inContext:self.mainQueueContext];
    completion([dialog toQBChatDialog]);
}

- (void)dialogsSortedBy:(NSString *)sortTerm
              ascending:(BOOL)ascending
          withPredicate:(NSPredicate *)predicate
             completion:(void(^)(NSArray<QBChatDialog *> *dialogs))completion {
    
    NSArray<CDDialog *> *cdChatDialogs =
    [CDDialog QM_findAllSortedBy:sortTerm
                       ascending:ascending
                   withPredicate:predicate
                       inContext:self.mainQueueContext];
    
    NSArray<QBChatDialog *> *allDialogs = [self dialogsFromCache:cdChatDialogs];
    completion(allDialogs);
}

#pragma mark Insert / Update / Delete

- (void)insertOrUpdateDialog:(QBChatDialog *)dialog completion:(dispatch_block_t)completion {
    
    [self insertOrUpdateDialogs:@[dialog] completion:completion];
}

- (void)insertOrUpdateDialogs:(NSArray *)dialogs completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        for (QBChatDialog *dialog in dialogs) {
            
            CDDialog *cachedDialog = [CDDialog QM_findFirstOrCreateByAttribute:@"dialogID"
                                                                     withValue:dialog.ID
                                                                     inContext:ctx];
            
            //            if (![dialog.updatedAt isEqualToDate:tDialog.updatedAt] ||
            //                dialog.unreadMessagesCount != tDialog.unreadMessagesCount) {
            //
            //                [cachedDialog updateWithQBChatDialog:dialog];
            //            }
            
            [cachedDialog updateWithQBChatDialog:dialog];
        }
        
        QMSLog(@"[%@] Dialogs to insert %tu, update %tu", NSStringFromClass([self class]),
               ctx.insertedObjects.count,
               ctx.updatedObjects.count);
        
    } finish:completion];
}

- (void)deleteDialogWithID:(NSString *)dialogID
                completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        [CDDialog QM_deleteAllMatchingPredicate:IS(@"dialogID", dialogID)
                                      inContext:ctx];
    } finish:completion];
}

- (void)deleteAllDialogsWithCompletion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        [CDDialog QM_truncateAllInContext:ctx];
    } finish:completion];
}

#pragma mark -
#pragma mark  Messages
#pragma mark -

- (NSArray<QBChatMessage *> *)messagesWithChachedMessages:(NSArray<CDMessage *> *)cached {
    
    NSParameterAssert(cached.count > 0);
    
    NSMutableArray<QBChatMessage *> *messages =
    [NSMutableArray arrayWithCapacity:cached.count];
    
    for (CDMessage *message in cached) {
        
        QBChatMessage *QBChatMessage = [message toQBChatMessage];
        [messages addObject:QBChatMessage];
    }
    
    return [messages copy];
}

#pragma mark Fetch Messages


- (NSArray<QBChatMessage *> *)messagesWithDialogId:(NSString *)dialogId
                                          sortedBy:(NSString *)sortTerm
                                         ascending:(BOOL)ascending {
    
    return nil;
    
}

- (void)messagesWithDialogId:(NSString *)dialogId
                    sortedBy:(NSString *)sortTerm
                   ascending:(BOOL)ascending
                  completion:(void(^)(NSArray<QBChatMessage *> *messages))completion {
    
    [self messagesWithPredicate:IS(@"dialogID", dialogId)
                       sortedBy:sortTerm
                      ascending:ascending
                     completion:completion];
}

- (void)messagesWithPredicate:(NSPredicate *)predicate
                     sortedBy:(NSString *)sortTerm
                    ascending:(BOOL)ascending
                   completion:(void(^)(NSArray<QBChatMessage *> *messages))completion {
    
    __weak __typeof(self)weakSelf = self;
    
    NSArray<CDMessage *> *messages =
    [CDMessage QM_findAllSortedBy:sortTerm
                        ascending:ascending
                    withPredicate:predicate
                        inContext:self.mainQueueContext];
    
    if (messages.count > 0) {
        
        completion([weakSelf messagesWithChachedMessages:messages]);
    }
    else {
        
        completion(@[]);
    }
}

#pragma mark Messages Limit

- (void)checkMessagesLimitForDialogWithID:(NSString *)dialogID
                           withCompletion:(dispatch_block_t)completion {
    
    if (self.messagesLimitPerDialog == NSNotFound) {
        
        if (completion) completion();
        return;
    }
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        NSPredicate *messagePredicate = IS(@"dialogID", dialogID);
        
        if ([CDMessage QM_countOfEntitiesWithPredicate:messagePredicate inContext:ctx] > self.messagesLimitPerDialog) {
            
            NSFetchRequest *oldestMessageRequest = [NSFetchRequest fetchRequestWithEntityName:[CDMessage entityName]];
            
            oldestMessageRequest.fetchOffset = self.messagesLimitPerDialog;
            oldestMessageRequest.predicate = messagePredicate;
            oldestMessageRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateSend" ascending:NO]];
            
            NSArray *oldestMessagesForDialogID = [CDMessage QM_executeFetchRequest:oldestMessageRequest inContext:ctx];
            
            for (CDMessage *oldestMessage in oldestMessagesForDialogID) {
                [ctx deleteObject:oldestMessage];
            }
            
        }
        
    } finish:completion];
}

#pragma mark Insert / Update / Delete

- (void)insertOrUpdateMessage:(QBChatMessage *)message
                 withDialogId:(NSString *)dialogID
                         read:(BOOL)isRead
                   completion:(dispatch_block_t)completion {
    
    message.dialogID = dialogID;
    message.read = isRead;
    
    [self insertOrUpdateMessage:message
                   withDialogId:dialogID
                     completion:completion];
}

- (void)insertOrUpdateMessage:(QBChatMessage *)message
                 withDialogId:(NSString *)dialogID
                   completion:(dispatch_block_t)completion {
    
    [self insertOrUpdateMessages:@[message]
                    withDialogId:dialogID
                      completion:completion];
}

- (void)insertOrUpdateMessages:(NSArray *)messages
                  withDialogId:(NSString *)dialogID
                    completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        for (QBChatMessage *message in messages) {
            
            CDMessage *procMessage =
            [CDMessage QM_findFirstOrCreateByAttribute:@"messageID"
                                             withValue:message.ID
                                             inContext:ctx];
            
            [procMessage updateWithQBChatMessage:message];
        }
        
        QMSLog(@"[%@] Messages to insert %tu, update %tu", NSStringFromClass([self class]),
               ctx.insertedObjects.count,
               ctx.updatedObjects.count);
        
    } finish:completion];
    
    //    [weakSelf save:^{
    //
    ////        if ([toInsert count] > 0) {
    ////
    ////            [weakSelf checkMessagesLimitForDialogWithID:dialogID withCompletion:completion];
    ////        }
    ////        else {
    ////
    ////        }
    //        if (completion) completion();
    //    }];
    
}

- (void)deleteMessage:(QBChatMessage *)message
           completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        [CDMessage QM_deleteAllMatchingPredicate:IS(@"messageID", message.ID)
                                       inContext:ctx];
    } finish:completion];
}

- (void)deleteMessages:(NSArray *)messages
            completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        for (QBChatMessage *message in messages) {
            
            CDMessage *messageToDelete =
            [CDMessage QM_findFirstByAttribute:@"messageID"
                                     withValue:message.ID
                                     inContext:ctx];
            
            [messageToDelete QM_deleteEntityInContext:ctx];
        }
        
    } finish:completion];
}

- (void)deleteMessageWithDialogID:(NSString *)dialogID
                       completion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        
        [CDMessage QM_deleteAllMatchingPredicate:IS(@"dialogID", dialogID)
                                       inContext:ctx];
    } finish:completion];
}

- (void)deleteAllMessagesWithCompletion:(dispatch_block_t)completion {
    
    [self save:^(NSManagedObjectContext *ctx) {
        [CDMessage QM_truncateAllInContext:ctx];
    } finish:completion];
}

@end
