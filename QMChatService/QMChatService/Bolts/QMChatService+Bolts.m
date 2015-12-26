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
