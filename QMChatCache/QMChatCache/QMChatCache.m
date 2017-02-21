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
        
        QBChatDialog *qbUser = [dialog toQBChatDialog];
        [qbChatDialogs addObject:qbUser];
    }
    
    return qbChatDialogs;
}

#pragma mark Fetch Dialogs

- (void)allDialogsWithCompletion:(void(^)(NSArray<QBChatDialog *> *dialogs))completion {
    
    __weak __typeof(self)weakSelf = self;
    
    [self async:^(NSManagedObjectContext *context) {
        
        NSArray *cdChatDialogs = [CDDialog QM_findAllInContext:context];
        NSArray *allDialogs = [weakSelf dialogsFromCache:cdChatDialogs];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(allDialogs);
        });
        
    }];
}
- (void)dialogsSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending completion:(void(^)(NSArray<QBChatDialog *> *dialogs))completion {
    
    [self dialogsSortedBy:sortTerm ascending:ascending withPredicate:nil completion:completion];
}

- (void)dialogByID:(NSString *)dialogID completion:(void (^)(QBChatDialog *cachedDialog))completion {
    
    __weak __typeof(self)weakSelf = self;
    
    [self async:^(NSManagedObjectContext *context) {
        
        NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(self.dialogID == [cd] %@)",dialogID];
        
        CDDialog *cdChatDialog = [CDDialog QM_findFirstWithPredicate:fetchPredicate inContext:context];
        
        QBChatDialog *dialog = nil;
        
        if (cdChatDialog) {
            dialog = [[weakSelf dialogsFromCache:@[cdChatDialog]] firstObject];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(dialog);
        });
        
    }];
}

- (void)dialogsSortedBy:(NSString *)sortTerm
              ascending:(BOOL)ascending
          withPredicate:(NSPredicate *)predicate
             completion:(void(^)(NSArray<QBChatDialog *> *dialogs))completion {
    
    __weak __typeof(self)weakSelf = self;
    NSArray *cdChatDialogs = [CDDialog QM_findAllSortedBy:sortTerm
                                                ascending:ascending
                                            withPredicate:predicate
                                                inContext:self.context];
    
    NSArray<QBChatDialog *> *allDialogs = [weakSelf dialogsFromCache:cdChatDialogs];
    
    completion(allDialogs);
}

#pragma mark Insert / Update / Delete

- (void)insertOrUpdateDialog:(QBChatDialog *)dialog completion:(dispatch_block_t)completion {
    
    [self insertOrUpdateDialogs:@[dialog] completion:completion];
}

- (void)insertOrUpdateDialogs:(NSArray *)dialogs completion:(dispatch_block_t)completion {
    
    __weak __typeof(self)weakSelf = self;
    
    [self async:^(NSManagedObjectContext *backgroundContext) {
        
        NSMutableArray *toUpdate = [NSMutableArray array];
        
        //To Insert / Update
        for (QBChatDialog *dialog in dialogs) {
            
            NSParameterAssert(dialog.ID);
            
            CDDialog *cachedDialog = [CDDialog QM_findFirstWithPredicate:IS(@"dialogID", dialog.ID)
                                                               inContext:backgroundContext];
            
            if (cachedDialog) {
                
                QBChatDialog *tDialog = [cachedDialog toQBChatDialog];
                
                if (![dialog.updatedAt isEqualToDate:tDialog.updatedAt] ||
                    dialog.unreadMessagesCount != tDialog.unreadMessagesCount) {
                    
                    [toUpdate addObject:dialog];
                }
            }
            else {
                
                CDDialog *dialogToInsert = [CDDialog QM_createEntityInContext:backgroundContext];
                [dialogToInsert updateWithQBChatDialog:dialog];
            }
        }
        
        if (toUpdate.count > 0) {
            
            [weakSelf updateQBChatDialogs:toUpdate inContext:backgroundContext];
        }
        
        if ([backgroundContext hasChanges]) {
            
            QMSLog(@"[%@] Dialogs to insert %tu, update %tu", NSStringFromClass([self class]),
                   backgroundContext.insertedObjects.count, backgroundContext.updatedObjects.count);

            [backgroundContext QM_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
                
                if (completion)
                    completion();
            }];
        }
        else {
            if (completion)
                completion();
        }
    }];
}

- (void)deleteDialogWithID:(NSString *)dialogID
                completion:(dispatch_block_t)completion {
    
    __weak __typeof(self)weakSelf = self;
    [self async:^(NSManagedObjectContext *backgroundContext) {
        
        CDDialog *dialogToDelete =
        [CDDialog QM_findFirstWithPredicate:IS(@"dialogID", dialogID)
                                  inContext:backgroundContext];
        
        [dialogToDelete QM_deleteEntityInContext:backgroundContext];
        
        [backgroundContext QM_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (completion)
                completion();
        }];
    }];
}

- (void)deleteAllDialogsWithCompletion:(dispatch_block_t)completion {
    
    __weak __typeof(self)weakSelf = self;
    [self async:^(NSManagedObjectContext *backgroundContext) {
        
        [CDDialog QM_truncateAllInContext:backgroundContext];
        
        [backgroundContext QM_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            completion();
        }];
    
    }];
}

#pragma mark Utils

- (void)updateQBChatDialogs:(NSArray *)qbChatDialogs inContext:(NSManagedObjectContext *)context {
    
    for (QBChatDialog *qbChatDialog in qbChatDialogs) {
        
        CDDialog *dialogToUpdate =
        [CDDialog QM_findFirstWithPredicate:IS(@"dialogID", qbChatDialog.ID) inContext:context];
        [dialogToUpdate updateWithQBChatDialog:qbChatDialog];
    }
}

#pragma mark -
#pragma mark  Messages
#pragma mark -

- (NSArray<QBChatMessage *> *)convertCDMessagesTOQBChatHistoryMesages:(NSArray<CDMessage *> *)cdMessages {
    
    NSParameterAssert(cdMessages.count > 0);
    
    NSMutableArray<QBChatMessage *> *messages =
    [NSMutableArray arrayWithCapacity:cdMessages.count];
    
    for (CDMessage *message in cdMessages) {
        
        QBChatMessage *QBChatMessage = [message toQBChatMessage];
        [messages addObject:QBChatMessage];
    }
    
    return [messages copy];
}

#pragma mark Fetch Messages

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
                        inContext:self.backgroundSaveContext];
    
    if (messages.count > 0) {
        
        completion([weakSelf convertCDMessagesTOQBChatHistoryMesages:messages]);
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
    
    [self async:^(NSManagedObjectContext *backgroundContext) {
        
        NSPredicate *messagePredicate = IS(@"dialogID", dialogID);
        
        if ([CDMessage QM_countOfEntitiesWithPredicate:messagePredicate inContext:backgroundContext] > self.messagesLimitPerDialog) {
            
            NSFetchRequest *oldestMessageRequest = [NSFetchRequest fetchRequestWithEntityName:[CDMessage entityName]];
            
            oldestMessageRequest.fetchOffset = self.messagesLimitPerDialog;
            oldestMessageRequest.predicate = messagePredicate;
            oldestMessageRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateSend" ascending:NO]];
            
            NSArray *oldestMessagesForDialogID = [CDMessage QM_executeFetchRequest:oldestMessageRequest inContext:backgroundContext];
            
            for (CDMessage *oldestMessage in oldestMessagesForDialogID) {
                [backgroundContext deleteObject:oldestMessage];
            }
            
            [backgroundContext QM_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                if (completion) completion();
            }];
            
        } else {
            
            if (completion) completion();
        }
        
    }];
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
    
    __weak __typeof(self)weakSelf = self;
    
    [self async:^(NSManagedObjectContext *backgroundContext) {
        
        NSMutableArray *toInsert = [NSMutableArray array];
        //To Insert / Update
        for (QBChatMessage *message in messages) {
            
            CDMessageID *itemID = [CDMessage QM_findFirstIDWithPredicate:IS(@"messageID", message.ID)
                                                               inContext:backgroundContext];
    
            CDMessage *procMessage = nil;
            if (itemID) {
                procMessage = [backgroundContext objectWithID:itemID];
            }
            else {
                procMessage = [CDMessage QM_createEntityInContext:backgroundContext];
            }
            
            [procMessage updateWithQBChatMessage:message];
        }
        
        QMSLog(@"[%@] Messages to insert %tu, update %tu", NSStringFromClass([self class]),
               backgroundContext.insertedObjects.count,
               backgroundContext.updatedObjects.count);
        
        
        if ([backgroundContext hasChanges]) {
            
            [backgroundContext QM_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
                
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), completion);
                }
            }];
        }
        else {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), completion);
                }
            });
        }
    }];
    
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

- (void)deleteMessages:(NSArray *)messages inContext:(NSManagedObjectContext *)context {
    
    for (QBChatMessage *QBChatMessage in messages) {
        
        [self deleteMessage:QBChatMessage inContext:context];
    }
}

- (void)updateMessages:(NSArray *)messages inContext:(NSManagedObjectContext *)context {
    
    for (QBChatMessage *message in messages) {
        CDMessage *messageToUpdate = [CDMessage QM_findFirstWithPredicate:IS(@"messageID", message.ID)
                                                                inContext:context];
        [messageToUpdate updateWithQBChatMessage:message];
    }
}

- (void)deleteMessage:(QBChatMessage *)message
            inContext:(NSManagedObjectContext *)context {
    
    CDMessage *messageToDelete = [CDMessage QM_findFirstWithPredicate:IS(@"messageID", message.ID)
                                                            inContext:context];
    [messageToDelete QM_deleteEntityInContext:context];
}

- (void)deleteMessagesWithDialogID:(NSString *)dialogID
                         inContext:(NSManagedObjectContext *)context {
    
    [CDMessage QM_deleteAllMatchingPredicate:IS(@"dialogID", dialogID)
                                   inContext:context];
}

- (void)deleteMessage:(QBChatMessage *)message
           completion:(dispatch_block_t)completion {
    
    __weak __typeof(self)weakSelf = self;
    
    [self async:^(NSManagedObjectContext *backgroundContext) {
        
        [weakSelf deleteMessage:message
                      inContext:backgroundContext];
        
        [backgroundContext QM_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
            completion();
        }];
    }];
}

- (void)deleteMessages:(NSArray *)messages
            completion:(dispatch_block_t)completion {
    
    __weak __typeof(self)weakSelf = self;
    [self async:^(NSManagedObjectContext *backgroundContext) {
        [weakSelf deleteMessages:messages inContext:backgroundContext];
        [backgroundContext QM_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
            completion();
        }];
    }];
}

- (void)deleteMessageWithDialogID:(NSString *)dialogID
                       completion:(dispatch_block_t)completion {
    
    __weak __typeof(self)weakSelf = self;
    [self async:^(NSManagedObjectContext *backgroundContext) {
        
        [weakSelf deleteMessagesWithDialogID:dialogID
                                   inContext:backgroundContext];
        [backgroundContext QM_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
            completion();
        }];
    }];
}

- (void)deleteAllMessagesWithCompletion:(dispatch_block_t)completion {
    
    __weak __typeof(self)weakSelf = self;
    [self async:^(NSManagedObjectContext *backgroundContext) {
        [CDMessage QM_truncateAllInContext:backgroundContext];
        
        [backgroundContext QM_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
            completion();
        }];
    }];
}

@end
