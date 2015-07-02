//
//  QMChatService+AttachmentService.h
//  QMChatService
//
//  Created by Injoit on 7/1/15.
//
//

#import "QMChatService.h"

@interface QMChatService (AttachmentService)

- (BOOL)sendMessage:(QBChatMessage *)message type:(QMMessageType)type toDialog:(QBChatDialog *)dialog save:(BOOL)save saveToStorage:(BOOL)saveToStorage completion:(void(^)(NSError *error))completion;

@end