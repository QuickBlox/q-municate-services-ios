//
//  QMChatGroupService.h
//  Qmunicate
//
//  Created by Andrey Ivanov on 02.07.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMBaseService.h"
#import "QMDialogsMemoryStorage.h"
#import "QMMessagesMemoryStorage.h"

@protocol QMChatServiceDelegate;
@protocol QMChatServiceCacheDelegate;

typedef void(^QMCacheCollection)(NSArray *collection);

/**
 *  Chat dialog service
 */
@interface QMChatService : QMBaseService

/**
 *  Dialogs datasoruce
 */
@property (strong, nonatomic, readonly) QMDialogsMemoryStorage *dialogsMemoryStorage;

/**
 *  Messages datasource
 */
@property (strong, nonatomic, readonly) QMMessagesMemoryStorage *messagesMemoryStorage;

/**
 *  Init chat service
 *
 *  @param serviceDataDelegate delegate confirmed QMServiceDataDelegate protocol
 *  @param cacheDelegate       delegate confirmed QMChatServiceCacheDelegate
 *
 *  @return Return QMChatService instance
 */
- (instancetype)initWithServiceDataDelegate:(id<QMServiceDataDelegate>)serviceDataDelegate
                              cacheDelegate:(id<QMChatServiceCacheDelegate>)cacheDelegate;
/**
 *  Init chat service
 *
 *  @param serviceDataDelegate instance confirmed QMServiceDataDelegate
 *
 *  @return QMChatService instance
 */
- (id)initWithServiceDataDelegate:(id<QMServiceDataDelegate>)serviceDataDelegate;

/**
 *  Add delegate (Multicast)
 *
 *  @param delegate delegate confirmed QMChatServiceDelegate protocol
 */
- (void)addDelegate:(id<QMChatServiceDelegate>)delegate;
- (void)addRemoveDelegate:(id<QMChatServiceDelegate>)delegate;

- (void)logIn:(void(^)(NSError *error))completion;
- (void)logoutChat;

- (void)createGroupChatDialogWithName:(NSString *)name
                            occupants:(NSArray *)occupants
                           completion:(void(^)(QBResponse *response, QBChatDialog *createdDialog))completion;

- (void)createPrivateChatDialogIfNeededWithOpponent:(QBUUser *)opponent
                                         completion:(void(^)(QBResponse *response, QBChatDialog *createdDialog))completion;

- (void)changeChatName:(NSString *)dialogName
         forChatDialog:(QBChatDialog *)chatDialog
            completion:(void(^)(QBResponse *response, QBChatDialog *updatedDialog))completion;

- (void)joinOccupantsWithIDs:(NSArray *)ids
                toChatDialog:(QBChatDialog *)chatDialog
                  completion:(void(^)(QBResponse *response, QBChatDialog *updatedDialog))completion;

- (void)fetchAllDialogs:(void(^)(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs))completion;

- (void)fetchMessageWithDialogID:(NSString *)chatDialogId
                        complete:(void(^)(QBResponse *response, NSArray *messages))completion;

- (void)sendText:(NSString *)text
        toDialog:(QBChatDialog *)dialog
      completion:(void(^)(QBChatMessage *message))completion;

- (void)sendAttachment:(NSString *)attachmentUrl
              toDialog:(QBChatDialog *)dialog
            completion:(void(^)(QBChatMessage *message))completion;

@end

@protocol QMChatServiceCacheDelegate <NSObject>
@required

- (void)cachedDialogs:(QMCacheCollection)block;
- (void)cachedMessagesWithDialogID:(NSString *)dialogID block:(QMCacheCollection)block;

@end

@protocol QMChatServiceDelegate <NSObject>
@optional

- (void)chatServiceDidLoadDialogsFromCache;
- (void)chatServiceDidLoadMessagesFromCacheForDialogID:(NSString *)dilaogID;

- (void)chatService:(QMChatService *)chatService didAddChatDialog:(QBChatDialog *)chatDialog;
- (void)chatService:(QMChatService *)chatService didAddChatDialogs:(NSArray *)chatDialogs;

- (void)chatServiceDidAddMessageToHistory:(QBChatMessage *)message forDialog:(QBChatDialog *)dialog;
- (void)chatServiceDidReceiveNotificationMessage:(QBChatMessage *)message createDialog:(QBChatDialog *)dialog;
- (void)chatServiceDidReceiveNotificationMessage:(QBChatMessage *)message updateDialog:(QBChatDialog *)dialog;

@end
