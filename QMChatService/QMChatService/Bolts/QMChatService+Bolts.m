//
//  QMChatService+QMChatService_Bolts.m
//  Pods
//
//  Created by Vitaliy Gorbachov on 12/26/15.
//
//

#import "QMChatService.h"

@implementation QMChatService (Bolts)

- (BFTask *)messagesWithChatDialogID:(NSString *)chatDialogID {
    
    BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
    
    [self messagesWithChatDialogID:chatDialogID completion:^(QBResponse *response, NSArray *messages) {
        //
        if (response.success) {
            //
            [source setResult:messages];
        } else {
            //
            [source setError:response.error.error];
        }
    }];
    
    return source.task;
}

- (BFTask *)fetchDialogWithID:(NSString *)dialogID {
    
    BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
    
    [self fetchDialogWithID:dialogID completion:^(QBChatDialog *dialog) {
        //
        [source setResult:dialog];
    }];
    
    return source.task;
}

@end
