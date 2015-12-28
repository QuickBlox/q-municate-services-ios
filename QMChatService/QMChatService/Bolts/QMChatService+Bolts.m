//
//  QMChatService+Bolts.m
//  QMServices
//
//  Created by Vitaliy Gorbachov on 12/26/15.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//

#import "QMChatService.h"

#define kQMLoadedAllMessages @1

@interface QMChatService()

@property (strong, nonatomic) QBMulticastDelegate <QMChatServiceDelegate, QMChatConnectionDelegate> *multicastDelegate;
@property (weak, nonatomic)   BFTask* loadEarlierMessagesTask;
@property (strong, nonatomic) NSMutableDictionary *loadedAllMessages;

@end

@implementation QMChatService (Bolts)

#pragma mark Chat dialog creation

- (BFTask *)createPrivateChatDialogWithOpponent:(QBUUser *)opponent {
    
    BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
    
    [self createPrivateChatDialogWithOpponent:opponent completion:^(QBResponse *response, QBChatDialog *createdDialog) {
        //
        if (response.success) {
            [source setResult:createdDialog];
        } else {
            [source setError:response.error.error];
        }
    }];
    
    return source.task;
}

- (BFTask *)createGroupChatDialogWithName:(NSString *)name photo:(NSString *)photo occupants:(NSArray *)occupants {
    
    BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
    
    [self createGroupChatDialogWithName:name photo:photo occupants:occupants completion:^(QBResponse *response, QBChatDialog *createdDialog) {
        //
        if (response.success) {
            [source setResult:createdDialog];
        } else {
            [source setError:response.error.error];
        }
    }];
    
    return source.task;
}

- (BFTask *)createPrivateChatDialogWithOpponentID:(NSUInteger)opponentID {
    
    BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
    
    [self createPrivateChatDialogWithOpponentID:opponentID completion:^(QBResponse *response, QBChatDialog *createdDialog) {
        //
        if (response.success) {
            [source setResult:createdDialog];
        } else {
            [source setError:response.error.error];
        }
    }];
    
    return source.task;
}

#pragma mark - Edit dialog methods

- (BFTask *)changeDialogName:(NSString *)dialogName forChatDialog:(QBChatDialog *)chatDialog {
    
    BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
    
    [self changeDialogName:dialogName forChatDialog:chatDialog completion:^(QBResponse *response, QBChatDialog *updatedDialog) {
        //
        if (response.success) {
            [source setResult:updatedDialog];
        } else {
            [source setError:response.error.error];
        }
    }];
    
    return source.task;
}

- (BFTask *)changeDialogAvatar:(NSString *)avatarPublicUrl forChatDialog:(QBChatDialog *)chatDialog {
    
    BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
    
    [self changeDialogAvatar:avatarPublicUrl forChatDialog:chatDialog completion:^(QBResponse *response, QBChatDialog *updatedDialog) {
        //
        if (response.success) {
            [source setResult:updatedDialog];
        } else {
            [source setError:response.error.error];
        }
    }];
    
    return source.task;
}

- (BFTask *)joinOccupantsWithIDs:(NSArray *)ids toChatDialog:(QBChatDialog *)chatDialog {
    
    BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
    
    [self joinOccupantsWithIDs:ids toChatDialog:chatDialog completion:^(QBResponse *response, QBChatDialog *updatedDialog) {
        //
        if (response.success) {
            [source setResult:updatedDialog];
        } else {
            [source setError:response.error.error];
        }
    }];
    
    return source.task;
}

#pragma mark Messages loading

- (BFTask *)messagesWithChatDialogID:(NSString *)chatDialogID {
    
    BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
    
    [self messagesWithChatDialogID:chatDialogID completion:^(QBResponse *response, NSArray *messages) {
        //
        if (response.success) {
            [source setResult:messages];
        } else {
            [source setError:response.error.error];
        }
    }];
    
    return source.task;
}

- (BFTask *)loadEarlierMessagesWithChatDialogID:(NSString *)chatDialogID {
    
    if ([self.loadedAllMessages[chatDialogID] isEqualToNumber: kQMLoadedAllMessages]) return [BFTask taskWithResult:@[]];
    
    if (self.loadEarlierMessagesTask == nil) {
        BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
        
        QBChatMessage *oldestMessage = [self.messagesMemoryStorage oldestMessageForDialogID:chatDialogID];
        
        if (oldestMessage == nil) return [BFTask taskWithResult:@[]];
        
        NSString *oldestMessageDate = [NSString stringWithFormat:@"%ld", (NSUInteger)[oldestMessage.dateSent timeIntervalSince1970]];
        
        QBResponsePage *page = [QBResponsePage responsePageWithLimit:self.chatMessagesPerPage];
        
        NSDictionary* parameters = @{
                                     @"date_sent[lt]" : oldestMessageDate,
                                     @"sort_desc"     : @"date_sent"
                                     };
        
        
        @weakify(self);
        [QBRequest messagesWithDialogID:chatDialogID extendedRequest:parameters forPage:page successBlock:^(QBResponse *response, NSArray *messages, QBResponsePage *page) {
            @strongify(self);
            
            if ([messages count] < self.chatMessagesPerPage) {
                self.loadedAllMessages[chatDialogID] = kQMLoadedAllMessages;
            }
            
            if ([messages count] > 0) {
                
                [self.messagesMemoryStorage addMessages:messages forDialogID:chatDialogID];
                
                if ([self.multicastDelegate respondsToSelector:@selector(chatService:didAddMessagesToMemoryStorage:forDialogID:)]) {
                    [self.multicastDelegate chatService:self didAddMessagesToMemoryStorage:messages forDialogID:chatDialogID];
                }
            }
            
            [source setResult:[[messages reverseObjectEnumerator] allObjects]];
            
        } errorBlock:^(QBResponse *response) {
            @strongify(self);
            
            // case where we may have deleted dialog from another device
            if( response.status != QBResponseStatusCodeNotFound ) {
                [self.serviceManager handleErrorResponse:response];
            }
            
            [source setError:response.error.error];
        }];
        
        self.loadEarlierMessagesTask = source.task;
        return self.loadEarlierMessagesTask;
    }
    
    return [BFTask taskWithResult:@[]];
}

#pragma mark - chat dialog fetching

- (BFTask *)fetchDialogWithID:(NSString *)dialogID {
    
    BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
    
    [self fetchDialogWithID:dialogID completion:^(QBChatDialog *dialog) {
        //
        [source setResult:dialog];
    }];
    
    return source.task;
}

- (BFTask *)loadDialogWithID:(NSString *)dialogID {
    
    QBResponsePage *responsePage = [QBResponsePage responsePageWithLimit:1 skip:0];
    NSMutableDictionary *extendedRequest = @{@"_id":dialogID}.mutableCopy;
    BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
    
    @weakify(self);
    [QBRequest dialogsForPage:responsePage extendedRequest:extendedRequest successBlock:^(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs, QBResponsePage *page) {
        @strongify(self);
        if ([dialogObjects firstObject] != nil) {
            [self.dialogsMemoryStorage addChatDialog:[dialogObjects firstObject] andJoin:YES completion:nil];
            if ([self.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogToMemoryStorage:)]) {
                [self.multicastDelegate chatService:self didAddChatDialogToMemoryStorage:[dialogObjects firstObject]];
            }
        }
        
        [source setResult:[dialogObjects firstObject]];
    } errorBlock:^(QBResponse *response) {
        @strongify(self);
        [self.serviceManager handleErrorResponse:response];
        [source setError:response.error.error];
    }];
    
    return source.task;
}

@end
