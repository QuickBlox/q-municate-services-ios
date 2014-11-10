//
//  QMChatDialogsService.m
//  Qmunicate
//
//  Created by Andrey Ivanov on 02.07.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMChatService.h"
#import "QBChatAbstractMessage+TextEncoding.h"
#import "NSString+GTMNSStringHTMLAdditions.h"
#import "QBChatAbstractMessage+CustomParameters.h"

const NSTimeInterval kQMPresenceTime = 30;

@interface QMChatService()

<QBChatDelegate>

@property (strong, nonatomic) QBMulticastDelegate <QMChatServiceDelegate> *multicastDelegate;
@property (strong, nonatomic) QMDialogsMemoryStorage *memoryStorage;
@property (copy, nonatomic) void(^chatSuccessBlock)(NSError *error);
@property (strong, nonatomic) NSTimer *presenceTimer;

@end

@implementation QMChatService

#pragma mark - Configure

- (id)initWithServiceDataDelegate:(id<QMServiceDataDelegate>)serviceDataDelegate {
    self = [super initWithServiceDataDelegate:serviceDataDelegate];
    
    if (self) {
        
        self.memoryStorage = [[QMDialogsMemoryStorage alloc] init];
        [QBChat.instance addDelegate:self];
    };
    
    return self;
}

#pragma mark - Clean data

- (void)cleanData {
    
    self.memoryStorage = nil;
    
    NSAssert(![QBChat.instance isLoggedIn], @"Need update this case");
    [self.presenceTimer invalidate];
    [QBChat.instance removeDelegate:self];
}

#pragma mark - Add / Remove Multicast delegate

- (void)addDelegate:(id<QMChatServiceDelegate>)delegate {
    [self.multicastDelegate addDelegate:delegate];
}

- (void)addRemoveDelegate:(id<QMChatServiceDelegate>)delegate{
    [self.multicastDelegate removeDelegate:delegate];
}

#pragma mark - QBChatDelegate

- (void)chatDidLogin {
    
    [QBChat instance].useMutualSubscriptionForContactList = YES;
    [QBChat instance].autoReconnectEnabled = YES;
    [QBChat instance].streamManagementEnabled = YES;
    
    if (self.chatSuccessBlock) {
        self.chatSuccessBlock(nil);
        self.chatSuccessBlock = nil;
    }
}

//- (void)chatDidNotLogin {
//
//    if (self.chatSuccessBlock){
//        self.chatSuccessBlock(NO);
//        self.chatSuccessBlock = nil;
//    }
//}

- (void)chatDidFailWithStreamError:(NSError *)error {
    
    if (self.chatSuccessBlock){
        self.chatSuccessBlock(error);
        self.chatSuccessBlock = nil;
    }
}

#pragma mark Handle messadges (QBChatDelegate)

- (void)chatRoomDidReceiveMessage:(QBChatMessage *)message fromRoomJID:(NSString *)roomJID {
    [self handleChatMessage:message];
}

- (void)chatDidReceiveMessage:(QBChatMessage *)message {
    [self handleChatMessage:message];
}

#pragma mark - Chat Login/Logout

- (void)logIn:(void(^)(NSError *error))completion {
    
    self.chatSuccessBlock = completion;
    QBUUser *user = [self.serviceDataDelegate serviceDataCurrentProfile];
    
    NSAssert(user, @"User == nil");
    
    if ([[QBChat instance] isLoggedIn]) {
        
        self.chatSuccessBlock(nil);
    }
    else {
        
        [[QBChat instance] loginWithUser:user];
    }
}

- (void)logoutChat {
    
    if ([[QBChat instance] isLoggedIn]) {
        [[QBChat instance] logout];
    }
}

#pragma mark - Presence

- (void)startSendPresence {
    
    NSAssert(!self.presenceTimer, @"Must be nil");
    
    self.presenceTimer =
    [NSTimer scheduledTimerWithTimeInterval:kQMPresenceTime
                                     target:[QBChat instance]
                                   selector:@selector(sendPresence)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)stopSendPresence {
    [self.presenceTimer invalidate];
    self.presenceTimer = nil;
}

#pragma mark - Handle Chat messages

- (void)handleChatMessage:(QBChatMessage *)message {
    
    NSAssert(message.cParamDialogID, @"Need update this case");
    
    if (message.cParamNotificationType == QMMessageNotificationTypeNone) {
        
        if (message.recipientID != message.senderID) {
            
            //            [self addMessageToHistory:message withDialogID:message.cParamDialogID];
            
            QBChatDialog *chatDialogToUpdate = [self.memoryStorage chatDialogWithID:message.cParamDialogID];
            chatDialogToUpdate.lastMessageText = message.encodedText;
            chatDialogToUpdate.lastMessageDate = [NSDate dateWithTimeIntervalSince1970:message.cParamDateSent.doubleValue];
            chatDialogToUpdate.unreadMessagesCount++;
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatServiceDidReceiveNotificationMessage:updateDialog:)]) {
                [self.multicastDelegate chatServiceDidReceiveNotificationMessage:message updateDialog:chatDialogToUpdate];
            }
        }
    }
    else if (message.cParamNotificationType == QMMessageNotificationTypeCreateDialog) {
        
        QBChatDialog *newChatDialog = [message chatDialogFromCustomParameters];
        //        [self addDialogsToHistory:@[newChatDialog] joinIfNeeded:YES];
        
        [self.multicastDelegate chatServiceDidReceiveNotificationMessage:message createDialog:newChatDialog];
    }
    else if (message.cParamNotificationType == QMMessageNotificationTypeUpdateDialog) {
        
        QBChatDialog *chatDialogToUpdate = [self.memoryStorage chatDialogWithID:message.cParamDialogID];
        
        if (chatDialogToUpdate == nil) {
            NSAssert(!chatDialogToUpdate, @"Dialog you are looking for not found.");
            return;
        }
        
        chatDialogToUpdate.name = message.cParamDialogName;
        
        [self.multicastDelegate chatServiceDidReceiveNotificationMessage:message
                                                            updateDialog:chatDialogToUpdate];
    }
}

#pragma mark - Dialog history

- (void)fetchAllDialogs:(void(^)(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs))completion {
    
    __weak __typeof(self)weakSelf = self;
    [QBRequest dialogsWithSuccessBlock:^(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs) {
        
        //        [weakSelf addDialogsToHistory:dialogObjects joinIfNeeded:YES];
        
        if (completion) {
            completion(response, dialogObjects, dialogsUsersIDs);
        }
        
    } errorBlock:^(QBResponse *response) {
        
        if (completion) {
            completion(response, nil, nil);
        }
    }];
}

//- (QBChatDialog *)chatDialogWithRoomJID:(NSString *)roomJID {
//
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.roomJID == %@", roomJID];
////    NSArray *allDialogs = [self dialogHistory];
//
//    QBChatDialog *dialog = [allDialogs filteredArrayUsingPredicate:predicate].firstObject;
//    return dialog;
//}
//

#pragma mark - Create Private/Group dialog

- (void)createPrivateChatDialogIfNeededWithOpponent:(QBUUser *)opponent
                                         completion:(void(^)(QBResponse *response, QBChatDialog *createdDialo))completion {
    
    QBChatDialog *dialog = [self.memoryStorage privateChatDialogWithOpponentID:opponent.ID];
    
    dialog = nil;
    
    if (!dialog) {
        
        QBChatDialog *chatDialog = [[QBChatDialog alloc] init];
        chatDialog.type = QBChatDialogTypePrivate;
        chatDialog.occupantIDs = @[@(opponent.ID)];
        
        __weak __typeof(self)weakSelf = self;
        [QBRequest createDialog:chatDialog successBlock:^(QBResponse *response, QBChatDialog *createdDialog) {
            
            //            [weakSelf addDialogsToHistory:@[createdDialog] joinIfNeeded:YES];
            [weakSelf sendNotificationWithType:QMMessageNotificationTypeCreateDialog
                                          text:@"created new chat"
                                  toRecipients:@[opponent]
                                    chatDialog:createdDialog];
            completion(response, createdDialog);
            
        } errorBlock:^(QBResponse *response) {
            
            completion(response, nil);
        }];
        
    }
    else {
        
        completion(nil, dialog);
    }
}

- (void)createGroupChatDialogWithName:(NSString *)name
                            occupants:(NSArray *)occupants
                           completion:(void(^)(QBResponse *response, QBChatDialog *createdDialog))completion {
    
    NSMutableSet *occupantIDs = [NSMutableSet set];
    for (QBUUser *user in occupants) {
        [occupantIDs addObject:@(user.ID)];
    }
    
    QBChatDialog *chatDialog = [[QBChatDialog alloc] init];
    chatDialog.name = name;
    chatDialog.occupantIDs = occupantIDs.allObjects;
    chatDialog.type = QBChatDialogTypeGroup;
    
    __weak __typeof(self)weakSelf = self;
    [QBRequest createDialog:chatDialog successBlock:^(QBResponse *response, QBChatDialog *createdDialog) {
        
        //        [weakSelf addDialogsToHistory:@[createdDialog] joinIfNeeded:YES];
        [weakSelf sendNotificationWithType:QMMessageNotificationTypeCreateDialog
                                      text:@"created new chat"
                              toRecipients:occupants
                                chatDialog:createdDialog];
        
        completion(response, createdDialog);
        
    } errorBlock:^(QBResponse *response) {
        
        completion(response, nil);
    }];
}

#pragma mark - Edit dialog methods

- (void)changeChatName:(NSString *)dialogName
         forChatDialog:(QBChatDialog *)chatDialog
            completion:(void(^)(QBResponse *response, QBChatDialog *updatedDialog))completion {
    
    __weak __typeof(self)weakSelf = self;
    NSArray *opponentsWithoutMe = nil;
    QBUpdateDialogParameters *updateParameters = [QBUpdateDialogParameters updateDialogWithDialogID:chatDialog.ID
                                                                                      dialogNewName:dialogName];
    
    [QBRequest updateDialog:updateParameters successBlock:^(QBResponse *response, QBChatDialog *updatedDialog) {
        
        chatDialog.name = dialogName;
        [weakSelf sendNotificationWithType:QMMessageNotificationTypeUpdateDialog
                                      text:[NSString stringWithFormat:@"New chat name - %@", dialogName]
                              toRecipients:opponentsWithoutMe
                                chatDialog:chatDialog];
        
        completion(response, updatedDialog);
        
    } errorBlock:^(QBResponse *response) {
        completion(response, nil);
    }];
}

- (void)joinOccupantsWithIDs:(NSArray *)ids
                toChatDialog:(QBChatDialog *)chatDialog
                  completion:(void(^)(QBResponse *response, QBChatDialog *updatedDialog))completion {
    
    NSArray *occupantsToJoinIDs = ids;
    NSArray *occupantsToNotify = @[];
    
    __weak __typeof(self)weakSelf = self;
    QBUpdateDialogParameters *updateParams = [QBUpdateDialogParameters updateDialogWithDialogID:chatDialog.ID
                                                                                 addedOccupants:occupantsToJoinIDs
                                                                               removedOccupants:nil];
    
    [QBRequest updateDialog:updateParams successBlock:^(QBResponse *response, QBChatDialog *updatedDialog) {
        
        //        [weakSelf addDialogsToHistory:@[updatedDialog] joinIfNeeded:NO];
        
        [weakSelf sendNotificationWithType:QMMessageNotificationTypeCreateDialog
                                      text:@"Created new dialog"
                              toRecipients:occupantsToJoinIDs
                                chatDialog:updatedDialog];
        
        [weakSelf sendNotificationWithType:QMMessageNotificationTypeUpdateDialog
                                      text:@"Added new users"
                              toRecipients:occupantsToNotify
                                chatDialog:updatedDialog];
        
        completion(response, updatedDialog);
        
    } errorBlock:^(QBResponse *response) {
        
        completion(response, nil);
    }];
}

#pragma mark - Notifications

- (QBChatMessage *)notification:(QMMessageNotificationType)type
                      recipient:(QBUUser *)recipient text:(NSString *)text
                     chatDialog:(QBChatDialog *)chatDialog {
    
    QBChatMessage *msg = [QBChatMessage message];
    
    msg.recipientID = recipient.ID;
    msg.text = text;
    msg.cParamNotificationType = type;
    msg.cParamDateSent = @((NSInteger)CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970);
    [msg setCustomParametersWithChatDialog:chatDialog];
    
    return msg;
}

- (void)sendNotificationWithType:(QMMessageNotificationType)type text:(NSString *)text
                    toRecipients:(NSArray *)recipients
                      chatDialog:(QBChatDialog *)chatDialog {
    
    QBUUser *currentUser = [self.serviceDataDelegate serviceDataCurrentProfile];
    NSString *notifMessage = [NSString stringWithFormat:@"%@ %@", currentUser.fullName, text];
    
    for (QBUUser *recipient in recipients) {
        
        QBChatMessage *notification = [self notification:type recipient:recipient
                                                    text:notifMessage
                                              chatDialog:chatDialog];
        
        [self sendMessage:notification
             withDialogID:chatDialog.ID
            saveToHistory:NO
               completion:^(NSError *error){}];
    }
}

//- (NSUInteger )occupantIDForPrivateChatDialog:(QBChatDialog *)chatDialog {
//
//    NSAssert(chatDialog.type == QBChatDialogTypePrivate, @"Chat dialog type != QBChatDialogTypePrivate");
//    NSAssert(chatDialog.occupantIDs.count == 2, @"Array of user ids in chat. For private chat count = 2");
//
//    NSInteger myID = [self.serviceDataDelegate serviceDataCurrentProfile].ID;
//
//    for (NSNumber *ID in chatDialog.occupantIDs) {
//
//        if (ID.integerValue != myID) {
//            return ID.integerValue;
//        }
//    }
//
//    NSAssert(nil, @"Need update this cace");
//    return 0;
//}

#pragma mark - Messages histroy

- (void)fetchMessageWithDialogID:(NSString *)chatDialogId complete:(void(^)(BOOL success))completion{
    
    __weak __typeof(self)weakSelf = self;
    //    [self.dbStorage cachedQBChatMessagesWithDialogId:chatDialogId qbMessages:^(NSArray *collection) {
    ////        [weakSelf setMessages:collection withDialogID:chatDialogId];
    //    }];
    
    [QBRequest messagesWithDialogID:chatDialogId successBlock:^(QBResponse *response, NSArray *messages) {
        //        [weakSelf.dbStorage cacheQBChatMessages:messages withDialogId:chatDialogId finish:^{
        ////            [weakSelf setMessages:messages.count ? messages.mutableCopy : @[].mutableCopy withDialogID:chatDialogId];
        //            completion(YES);
        //        }];
        
    } errorBlock:^(QBResponse *response) {
        completion(NO);
    }];
}


#pragma mark - Send messages

- (void)sendMessage:(QBChatMessage *)message
       withDialogID:(NSString *)dialogID
      saveToHistory:(BOOL)save completion:(void(^)(NSError *error))completion {
    
    message.cParamDialogID = dialogID;
    message.cParamDateSent = @((NSInteger)CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970);
    message.text = [message.text gtm_stringByEscapingForHTML];
    
    if (save) {
        message.cParamSaveToHistory = @"1";
        message.markable = YES;
    }
    
    if ([[QBChat instance] sendMessage:message]) {
        completion(nil);
    }
}

- (void)sendMessage:(QBChatMessage *)message
           toDialog:(QBChatDialog *)dialog
         completion:(void(^)(QBChatMessage *message))completion {
    
    __weak __typeof(self)weakSelf = self;
    
    QBUUser *currentUser = [self.serviceDataDelegate serviceDataCurrentProfile];
    
    void (^finish)(QBChatMessage *historyMessage) = ^(QBChatMessage *historyMessage){
        
        historyMessage.senderID = currentUser.ID;
        //        [weakSelf addMessageToHistory:historyMessage withDialogID:dialog.ID];
        dialog.lastMessageText = historyMessage.encodedText;
        dialog.lastMessageDate = historyMessage.datetime;
        
        [weakSelf.multicastDelegate chatServiceDidDialogsHistoryUpdated];
        
        completion(message);
    };
    
    if (dialog.type == QBChatDialogTypeGroup) {
        
        message.cParamDialogID = dialog.ID;
        message.cParamSaveToHistory = @"1";
        message.cParamDateSent = @((NSInteger)CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970);
        message.text = [message.text gtm_stringByEscapingForHTML];
        
        if ([[QBChat instance] sendChatMessage:message
                                        toRoom:dialog.chatRoom])
        {
            finish(message);
        }
        
    } else if (dialog.type == QBChatDialogTypePrivate) {
        
        message.senderID = currentUser.ID;
        message.recipientID = dialog.recipientID;
        
        [self sendMessage:message
             withDialogID:dialog.ID
            saveToHistory:YES
               completion:^(NSError *error)
         {
             finish(message);
         }];
    }
}

- (void)sendText:(NSString *)text
        toDialog:(QBChatDialog *)dialog
      completion:(void(^)(QBChatMessage * message))completion {
    
    QBChatMessage *message = [[QBChatMessage alloc] init];
    message.text = text;
    
    [self sendMessage:message
             toDialog:dialog
           completion:completion];
}

- (void)sendAttachment:(NSString *)attachmentUrl
              toDialog:(QBChatDialog *)dialog
            completion:(void(^)(QBChatMessage * message))completion {
    
    QBChatMessage *message = [[QBChatMessage alloc] init];
    message.text = @"Attachment";
    
    QBChatAttachment *attachment = [[QBChatAttachment alloc] init];
    attachment.url = attachmentUrl;
    attachment.type = @"image";
    message.attachments = @[attachment];
    
    [self sendMessage:message
             toDialog:dialog
           completion:completion];
}

@end
