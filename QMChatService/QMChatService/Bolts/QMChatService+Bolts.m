//
//  QMChatService+Bolts.m
//  QMServices
//
//  Created by Vitaliy Gorbachov on 12/26/15.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//

#import "QMChatService.h"

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

#pragma mark - chat dialog fetching

- (BFTask *)fetchDialogWithID:(NSString *)dialogID {
    
    BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
    
    [self fetchDialogWithID:dialogID completion:^(QBChatDialog *dialog) {
        //
        [source setResult:dialog];
    }];
    
    return source.task;
}

@end
