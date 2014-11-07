//
//  QMChatCache.m
//  QMChatCache
//
//  Created by Andrey on 06.11.14.
//
//

#import "QMChatCache.h"
#import "ModelIncludes.h"

NSString *const kCDMessageDatetimePath = @"datetime";

@implementation QMChatCache

- (void)addQBChatMessagesInDialog:(id)dialog {
    
}

- (void)cacheQBDialogs:(NSArray *)dialogs finish:(void(^)(void))finish {
    
    __weak __typeof(self)weakSelf = self;
    
    [self async:^(NSManagedObjectContext *context) {
        [weakSelf mergeQBChatDialogs:dialogs inContext:context finish:finish];
    }];
}

- (void)cachedQBChatDialogs:(void(^)(NSArray *array))qbDialogs {
    
    __weak __typeof(self)weakSelf = self;
    [self async:^(NSManagedObjectContext *context) {
        NSArray *allDialogs = [weakSelf allQBChatDialogsInContext:context];
        DO_AT_MAIN(qbDialogs(allDialogs));
    }];
}

- (NSArray *)allQBChatDialogsInContext:(NSManagedObjectContext *)context {
    
    NSArray *cdChatDialogs = [CDDialog MR_findAllInContext:context];
    NSArray *result = (cdChatDialogs.count == 0) ? @[] : [self qbChatDialogsWithcdDialogs:cdChatDialogs];
    
    return result;
}

- (NSArray *)qbChatDialogsWithcdDialogs:(NSArray *)cdDialogs {
    
    NSMutableArray *qbChatDialogs = [NSMutableArray arrayWithCapacity:cdDialogs.count];
    
    for (CDDialog *dialog in cdDialogs) {
        QBChatDialog *qbUser = [dialog toQBChatDialog];
        [qbChatDialogs addObject:qbUser];
    }
    
    return qbChatDialogs;
}

- (void)mergeQBChatDialogs:(NSArray *)qbChatDialogs inContext:(NSManagedObjectContext *)context finish:(void(^)(void))finish {
    
    NSMutableArray *toInsert = [NSMutableArray array];
    NSMutableArray *toUpdate = [NSMutableArray array];
    
    //Update/Insert/Delete
    
    for (QBChatDialog *dialog in qbChatDialogs) {
        
        CDDialog *cdChatDialog = [CDDialog MR_findFirstWithPredicate:IS(@"id", dialog.ID) inContext:context];
        
        if (cdChatDialog) {
            
            QBChatDialog *dialogInCache = [cdChatDialog toQBChatDialog];
            if (![qbChatDialogs containsObject:dialogInCache]) {
                [toUpdate addObject:dialog];
            }
        }
        else {
            [toInsert addObject:dialog];
        }
    }
    
    if (toUpdate.count != 0) {
        [self updateQBChatDialogs:toUpdate inContext:context];
    }
    
    if (toInsert.count != 0) {
        [self insertQBChatDialogs:toInsert inContext:context];
    }
    
    if (toInsert.count + toInsert.count == 0) {
        finish();
    }
    else {
        [self save:finish];
    }
    
    NSLog(@"Users to insert %lu", (unsigned long)toInsert.count);
    NSLog(@"Users to update %lu", (unsigned long)toUpdate.count);
}

- (void)insertQBChatDialogs:(NSArray *)qbChatDialogs inContext:(NSManagedObjectContext *)context {
    
    for (QBChatDialog *qbChatDialog in qbChatDialogs) {
        CDDialog *dialogToInsert = [CDDialog MR_createEntityInContext:context];
        [dialogToInsert updateWithQBChatDialog:qbChatDialog];
    }
}

- (void)deleteQBChatDialogs:(NSArray *)qbChatDialogs inContext:(NSManagedObjectContext *)context {
    
    
    for (QBChatDialog *qbChatDialog in qbChatDialogs) {
        CDDialog *dialogToDelete = [CDDialog MR_findFirstWithPredicate:IS(@"id", qbChatDialog.ID)
                                                             inContext:context];
        [dialogToDelete MR_deleteEntityInContext:context];
    }
}

- (void)updateQBChatDialogs:(NSArray *)qbChatDialogs inContext:(NSManagedObjectContext *)context {
    
    for (QBChatDialog *qbChatDialog in qbChatDialogs) {
        CDDialog *dialogToUpdate = [CDDialog MR_findFirstWithPredicate:IS(@"id", qbChatDialog.ID)
                                                             inContext:context];
        [dialogToUpdate updateWithQBChatDialog:qbChatDialog];
    }
}

#pragma mark - Messages

- (void)cacheQBChatMessages:(NSArray *)messages withDialogId:(NSString *)dialogId finish:(void(^)(void))finish {
    
    __weak __typeof(self)weakSelf = self;
    START_LOG_TIME
    [self async:^(NSManagedObjectContext *context) {
        [weakSelf mergeQBChatHistoryMessages:messages withDialogId:dialogId inContext:context finish:^{
            END_LOG_TIME
            finish();
        }];
    }];
}

- (void)cachedQBChatMessagesWithDialogId:(NSString *)dialogId qbMessages:(void(^)(NSArray *array))qbMessages {
    
    __weak __typeof(self)weakSelf = self;
    [self async:^(NSManagedObjectContext *context) {
        
        NSArray *messages = [CDMessage MR_findAllSortedBy:kCDMessageDatetimePath
                                                ascending:NO
                                            withPredicate:IS(@"dialogId", dialogId)
                                                inContext:context];
        NSArray *result = [weakSelf qbChatHistoryMessagesWithcdMessages:messages];
        
        DO_AT_MAIN(qbMessages(result));
        
    }];
}

- (void)allCachedQBChatMessages:(void(^)(NSArray *array))qbMessages {
    
    __weak __typeof(self)weakSelf = self;
    [self async:^(NSManagedObjectContext *context) {
        
        NSArray *messages = [CDMessage MR_findAllSortedBy:kCDMessageDatetimePath
                                                ascending:NO
                                                inContext:context];
        
        NSArray *result = [weakSelf qbChatHistoryMessagesWithcdMessages:messages];
        
        DO_AT_MAIN(qbMessages(result));
    }];
}

- (void)insertNewMessages:(NSArray *)messages inContext:(NSManagedObjectContext *)context {
    
    for (QBChatHistoryMessage *chatMessage in messages) {
        
        CDMessage *message = [CDMessage MR_createEntityInContext:context];
        [message updateWithQBChatHistoryMessage:chatMessage];
    }
}

- (NSArray *)allQBChatHistoryMessagesWithDialogId:(NSString *)dialogId InContext:(NSManagedObjectContext *)context {
    
    NSArray *cdChatHistoryMessages = [CDMessage MR_findAllSortedBy:kCDMessageDatetimePath
                                                         ascending:NO
                                                     withPredicate:IS(@"dialogId", dialogId)
                                                         inContext:context];
    
    NSArray *result = (cdChatHistoryMessages.count == 0) ? @[] : [self qbChatHistoryMessagesWithcdMessages:cdChatHistoryMessages];
    
    return result;
}

- (NSArray *)qbChatHistoryMessagesWithcdMessages:(NSArray *)cdMessages {
    
    NSMutableArray *qbChatHistoryMessages = [NSMutableArray arrayWithCapacity:cdMessages.count];
    
    for (CDMessage *message in cdMessages) {
        QBChatHistoryMessage *qbChatHistoryMessage = [message toQBChatHistoryMessage];
        [qbChatHistoryMessages addObject:qbChatHistoryMessage];
    }
    
    return qbChatHistoryMessages;
}

- (void)mergeQBChatHistoryMessages:(NSArray *)qbChatHistoryMessages
                      withDialogId:(NSString *)dialogId
                         inContext:(NSManagedObjectContext *)context
                            finish:(void(^)(void))finish {
    
    NSArray *allQBChatHistoryMessagesInCache = [self allQBChatHistoryMessagesWithDialogId:dialogId
                                                                                InContext:context];
    
    NSMutableArray *toInsert = [NSMutableArray array];
    NSMutableArray *toUpdate = [NSMutableArray array];
    NSMutableArray *toDelete = [NSMutableArray arrayWithArray:allQBChatHistoryMessagesInCache];
    
    //Update/Insert/Delete
    
    for (QBChatHistoryMessage *historyMessage in qbChatHistoryMessages) {
        
        NSInteger idx = [allQBChatHistoryMessagesInCache indexOfObject:historyMessage];
        
        if (idx == NSNotFound) {
            
            QBChatHistoryMessage *chatHistoryMessageToUpdate = nil;
            
            for (QBChatHistoryMessage *candidateToUpdate in allQBChatHistoryMessagesInCache) {
                
                if ([candidateToUpdate.ID isEqual: historyMessage.ID]) {
                    
                    chatHistoryMessageToUpdate = historyMessage;
                    [toDelete removeObject:candidateToUpdate];
                    
                    break;
                }
            }
            
            if (chatHistoryMessageToUpdate) {
                [toUpdate addObject:chatHistoryMessageToUpdate];
            } else {
                [toInsert addObject:historyMessage];
            }
            
        } else {
            [toDelete removeObject:historyMessage];
        }
    }
    
    if (toUpdate.count != 0) {
        [self updateQBChatHistoryMessages:toUpdate inContext:context];
    }
    
    if (toInsert.count != 0) {
        [self insertQBChatHistoryMessages:toInsert inContext:context];
    }
    
    if (toDelete.count != 0) {
        [self deleteQBChatHistoryMessages:toDelete inContext:context];
    }
    
    NSLog(@"/////////////////////////////////");
    NSLog(@"Chat history in cahce %lu objects by id %@", (unsigned long)allQBChatHistoryMessagesInCache.count, dialogId);
    NSLog(@"Messages to insert %lu", (unsigned long)toInsert.count);
    NSLog(@"Messages to update %lu", (unsigned long)toUpdate.count);
    NSLog(@"Messages to delete %lu", (unsigned long)toDelete.count);
    NSLog(@"/////////////////////////////////");
    [self save:finish];
}

- (void)insertQBChatHistoryMessages:(NSArray *)qbChatHistoryMessages inContext:(NSManagedObjectContext *)context {
    
    for (QBChatHistoryMessage *qbChatHistoryMessage in qbChatHistoryMessages) {
        CDMessage *messageToInsert = [CDMessage MR_createEntityInContext:context];
        [messageToInsert updateWithQBChatHistoryMessage:qbChatHistoryMessage];
    }
}

- (void)deleteQBChatHistoryMessages:(NSArray *)qbChatHistoryMessages inContext:(NSManagedObjectContext *)context {
    
    
    for (QBChatHistoryMessage *qbChatHistoryMessage in qbChatHistoryMessages) {
        CDMessage *messageToDelete = [CDMessage MR_findFirstWithPredicate:IS(@"id", qbChatHistoryMessage.ID)
                                                                inContext:context];
        [messageToDelete MR_deleteEntityInContext:context];
    }
}

- (void)updateQBChatHistoryMessages:(NSArray *)qbChatHistoryMessages inContext:(NSManagedObjectContext *)context {
    
    for (QBChatHistoryMessage *qbChatHistoryMessage in qbChatHistoryMessages) {
        CDMessage *messageToUpdate = [CDMessage MR_findFirstWithPredicate:IS(@"id", qbChatHistoryMessage.ID)
                                                                inContext:context];
        [messageToUpdate updateWithQBChatHistoryMessage:qbChatHistoryMessage];
    }
}

@end
