//
//  QMChatGroupService.h
//  Q-municate
//
//  Created by Andrey Ivanov on 02.07.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMBaseService.h"
#import "QMDialogsMemoryStorage.h"
#import "QMMessagesMemoryStorage.h"
#import "QMChatTypes.h"

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
- (instancetype)initWithUserProfileDataSource:(id<QMUserProfileProtocol>)userProfileDataSource
                                cacheDelegate:(id<QMChatServiceCacheDelegate>)cacheDelegate;
/**
 *  Add delegate (Multicast)
 *
 *  @param delegate Instance confirmed QMChatServiceDelegate protocol
 */
- (void)addDelegate:(id<QMChatServiceDelegate>)delegate;

/**
 *  Remove delegate from observed list
 *
 *  @param delegate Instance confirmed QMChatServiceDelegate protocol
 */
- (void)addRemoveDelegate:(id<QMChatServiceDelegate>)delegate;

/**
 *  Login to chant
 *
 *  @param completion <#completion description#>
 */
- (void)logIn:(void(^)(NSError *error))completion;

/**
 *  Logout from chat
 */
- (void)logoutChat;
/**
 *  <#Description#>
 *
 *  @param name       <#name description#>
 *  @param occupants  <#occupants description#>
 *  @param completion <#completion description#>
 */
- (void)createGroupChatDialogWithName:(NSString *)name photo:(NSString *)photo occupants:(NSArray *)occupants
                           completion:(void(^)(QBResponse *response, QBChatDialog *createdDialog))completion;
/**
 *  <#Description#>
 *
 *  @param opponent   <#opponent description#>
 *  @param completion <#completion description#>
 */
- (void)createPrivateChatDialogWithOpponent:(QBUUser *)opponent
                                 completion:(void(^)(QBResponse *response, QBChatDialog *createdDialog))completion;
/**
 *  <#Description#>
 *
 *  @param dialogName <#dialogName description#>
 *  @param chatDialog <#chatDialog description#>
 *  @param completion <#completion description#>
 */
- (void)changeChatName:(NSString *)dialogName forChatDialog:(QBChatDialog *)chatDialog
            completion:(void(^)(QBResponse *response, QBChatDialog *updatedDialog))completion;
/**
 *  <#Description#>
 *
 *  @param ids        <#ids description#>
 *  @param chatDialog <#chatDialog description#>
 *  @param completion <#completion description#>
 */
- (void)joinOccupantsWithIDs:(NSArray *)ids toChatDialog:(QBChatDialog *)chatDialog
                  completion:(void(^)(QBResponse *response, QBChatDialog *updatedDialog))completion;
/**
 *  <#Description#>
 *
 *  @param completion <#completion description#>
 */
- (void)dialogs:(void(^)(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs))completion;

#pragma mark - Fetch messages

- (void)messageWithChatDialogID:(NSString *)chatDialogID completion:(void(^)(QBResponse *response, NSArray *messages))completion;

#pragma mark Send message

- (void)sendMessage:(QBChatMessage *)message toDialog:(QBChatDialog *)dialog type:(QMMessageType)type save:(BOOL)save completion:(void(^)(NSError *error))completion;

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

- (void)chatServiceDidAddMessageToHistory:(QBChatMessage *)message forDialogID:(NSString *)dialogID;
- (void)chatServiceDidAddMessagesToHistroy:(NSArray *)messages forDialogID:(NSString *)dialogID;

- (void)chatServiceDidReceiveNotificationMessage:(QBChatMessage *)message createDialog:(QBChatDialog *)dialog;
- (void)chatServiceDidReceiveNotificationMessage:(QBChatMessage *)message updateDialog:(QBChatDialog *)dialog;

@end
