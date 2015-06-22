//
//  QMChatService.h
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
@protocol QMChatServiceCacheDataSource;

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
 *  @param serviceManager   delegate confirmed QMServiceManagerProtocol protocol
 *  @param cacheDataSource  delegate confirmed QMChatServiceCacheDataSource
 *
 *  @return Return QMChatService instance
 */
- (instancetype)initWithServiceManager:(id<QMServiceManagerProtocol>)serviceManager
                         cacheDataSource:(id<QMChatServiceCacheDataSource>)cacheDataSource;
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
- (void)removeDelegate:(id<QMChatServiceDelegate>)delegate;

/**
 *  Login to chant
 *
 *  @param completion The block which informs whether a chat did login or not. nil if no errors.
 */
- (void)logIn:(void(^)(NSError *error))completion;

/**
 *  Logout from chat
 */
- (void)logoutChat;

/**
 *  Automatically send chat presences when logged in
 *  Default value: YES
 */
@property (nonatomic, assign) BOOL automaticallySendPresences;

/**
 *  Default value: 45 seconds
 */
@property (nonatomic, assign) NSTimeInterval presenceTimerInterval;

- (void)joinToGroupDialog:(QBChatDialog *)dialog
               failed:(void(^)(NSError *error))failed;

/**
 *  Create group dilog
 *
 *  @param name       Dialog name
 *  @param occupants  QBUUser collection
 *  @param completion Block with response and created chat dialog instances
 */
- (void)createGroupChatDialogWithName:(NSString *)name photo:(NSString *)photo occupants:(NSArray *)occupants
                           completion:(void(^)(QBResponse *response, QBChatDialog *createdDialog))completion;
/**
 *  Create p2p dialog
 *
 *  @param opponent   QBUUser opponent
 *  @param completion Block with response and created chat dialog instances
 */
- (void)createPrivateChatDialogWithOpponent:(QBUUser *)opponent
                                 completion:(void(^)(QBResponse *response, QBChatDialog *createdDialog))completion;

/**
 *  Create p2p dialog
 *
 *  @param opponentID Opponent ID
 *  @param completion Block with response and created chat dialog instances
 */
- (void)createPrivateChatDialogWithOpponentID:(NSUInteger)opponentID
                                   completion:(void(^)(QBResponse *response, QBChatDialog *createdDialo))completion;

/**
 *  Change dialog name
 *
 *  @param dialogName Dialog name
 *  @param chatDialog QBChatDialog instane
 *  @param completion Block with response and updated chat dialog instances
 */
- (void)changeDialogName:(NSString *)dialogName forChatDialog:(QBChatDialog *)chatDialog
              completion:(void(^)(QBResponse *response, QBChatDialog *updatedDialog))completion;

/**
 *  Join occupants
 *
 *  @param ids        Occupants ids
 *  @param chatDialog QBChatDialog instance
 *  @param completion Block with response and updated chat dialog instances
 */
- (void)joinOccupantsWithIDs:(NSArray *)ids toChatDialog:(QBChatDialog *)chatDialog
                  completion:(void(^)(QBResponse *response, QBChatDialog *updatedDialog))completion;

/**
 *  Delete dialog by id on server and chat cache
 *
 *  @param completion Block with response dialogs instances
 */
- (void)deleteDialogWithID:(NSString *)dialogId
                completion:(void(^)(QBResponse *response))completion;

/**
 *  Retrieve chat dialogs
 *
 *  @param extendedRequest Set of request parameters. http://quickblox.com/developers/SimpleSample-chat_users-ios#Filters
 *  @param completion Block with response dialogs instances
 */
- (void)allDialogsWithPageLimit:(NSUInteger)limit
                extendedRequest:(NSDictionary *)extendedRequest
                interationBlock:(void(^)(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs, BOOL *stop))interationBlock
                     completion:(void(^)(QBResponse *response))completion;

#pragma mark - System Messages
/**
 *  Notify opponents about creating the dialog
 *
 *  @param dialog created dialog we notificate about
 *  @param usersIDs [NSNumber] array of OccupantIDs which not be notified
 */
- (void)notifyUsersWithIDs:(NSArray *)usersIDs aboutAddingToDialog:(QBChatDialog *)dialog;

/**
 *  Notify opponents about update the dialog
 *
 *  @param leaveDialog leave dialog
 *  @param occupantsCustomParameters {NSNumber : NSDictionary} dictionary of custom parameters for each occupant
 *  @param notificationText notification text
 *  @param completion completion block
 */
- (void)notifyAboutUpdateDialog:(QBChatDialog *)updatedDialog
      occupantsCustomParameters:(NSDictionary *)occupantsCustomParameters
               notificationText:(NSString *)notificationText
                     completion:(void (^)(NSError *error))completion;

/**
 *  Notify opponent about accept or reject contact request
 *
 *  @param accept     YES - accept, NO reject
 *  @param opponent   opponent ID
 *  @param completion Block 
 */
- (void)notifyOponentAboutAcceptingContactRequest:(BOOL)accept
                                       opponentID:(NSUInteger)opponentID
                                       completion:(void(^)(NSError *error))completion;

#pragma mark - Fetch messages

/**
 *  Fetch messages with chat dialog id
 *
 *  @param chatDialogID Chat dialog id
 *  @param completion   Block with response instance and array of chat messages if request succeded or nil if filed
 */

- (void)messagesWithChatDialogID:(NSString *)chatDialogID completion:(void(^)(QBResponse *response, NSArray *messages))completion;

#pragma mark Send message

/**
 *  Send message to dialog
 *
 *  @param message    QBChatMessage instance
 *  @param dialog     QBChatDialog instance
 *  @param save       completion Send message result
 */
- (void)sendMessage:(QBChatMessage *)message toDialog:(QBChatDialog *)dialog save:(BOOL)save completion:(void(^)(NSError *error))completion;

/**
 *  Send message to dialog with identifier
 *
 *  @param message    QBChatMessage instance
 *  @param dialogID   NSString dialog
 *  @param save       BOOL save
 *  @param completion completion Send message result
 */
- (void)sendMessage:(QBChatMessage *)message toDialogId:(NSString *)dialogID save:(BOOL)save completion:(void (^)(NSError *))completion;

@end

@protocol QMChatServiceCacheDataSource <NSObject>
@required
 
/**
 * Is called when chat service will start. Need to use for inserting initial data QMDialogsMemoryStorage
 *
 *  @param block Block for provide QBChatDialogs collection
 */
- (void)cachedDialogs:(QMCacheCollection)block;

/**
 *  Is called when begin fetch messages. @see -messagesWithChatDialogID:completion:
 *  Need to use for inserting initial data QMMessagesMemoryStorage by dialogID
 *
 *  @param dialogID Dialog ID
 *  @param block    Block for provide QBChatMessages collection
 */
- (void)cachedMessagesWithDialogID:(NSString *)dialogID block:(QMCacheCollection)block;

@end

@protocol QMChatServiceDelegate <NSObject>
@optional

- (void)chatService:(QMChatService *)chatService didLoadMessagesFromCache:(NSArray *)messages forDialogID:(NSString *)dialogID;

- (void)chatService:(QMChatService *)chatService didAddChatDialogToMemoryStorage:(QBChatDialog *)chatDialog;
- (void)chatService:(QMChatService *)chatService didAddChatDialogsToMemoryStorage:(NSArray *)chatDialogs;
- (void)chatService:(QMChatService *)chatService didUpdateChatDialogInMemoryStorage:(QBChatDialog *)chatDialog;

- (void)chatService:(QMChatService *)chatService didDeleteChatDialogWithIDFromMemoryStorage:(NSString *)chatDialogID;

- (void)chatService:(QMChatService *)chatService didAddMessageToMemoryStorage:(QBChatMessage *)message forDialogID:(NSString *)dialogID;
- (void)chatService:(QMChatService *)chatService didAddMessagesToMemoryStorage:(NSArray *)messages forDialogID:(NSString *)dialogID;

- (void)chatService:(QMChatService *)chatService  didReceiveNotificationMessage:(QBChatMessage *)message createDialog:(QBChatDialog *)dialog;

@end
