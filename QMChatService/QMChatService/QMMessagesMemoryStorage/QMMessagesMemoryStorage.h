//
//  QMMessagesMemoryStorage.h
//  QMChatService
//
//  Created by Andrey on 28.11.14.
//
//

#import <Foundation/Foundation.h>

@interface QMMessagesMemoryStorage : NSObject

/**
 *  Add message to memory storage
 *
 *  @param message  QBChatMessage instnace
 *  @param dialogID Chat dialog identifier
 */
- (void)addMessage:(QBChatMessage *)message
       forDialogID:(NSString *)dialogID;

/**
 *  Replace messages in memory storage for dialog identifier
 *
 *  @param messages Array of QBChatMessage instances to replace
 *  @param dialogID Chat dialog identifier
 */
- (void)replaceMessages:(NSArray *)messages
            forDialogID:(NSString *)dialogID;

#pragma mark - Getters
/**
 *  Messages with chat dialog identifier
 *
 *  @param dialogID Chat dialog identifier
 *
 *  @return return array of QBChatMessage instances
 */
- (NSArray *)messagesWithDialogID:(NSString *)dialogID;

#pragma mark - Clean up

- (void)cleanUp;

@end
