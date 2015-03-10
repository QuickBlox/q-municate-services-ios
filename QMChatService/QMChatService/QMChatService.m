//
//  QMChatDialogsService.m
//  Q-municate
//
//  Created by Andrey Ivanov on 02.07.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMChatService.h"
#import "QBChatAbstractMessage+TextEncoding.h"
#import "NSString+GTMNSStringHTMLAdditions.h"
#import "QBChatAbstractMessage+QMCustomParameters.h"

const NSTimeInterval kQMPresenceTimeIntervalInSec = 30;

@interface QMChatService()

<QBChatDelegate>

@property (strong, nonatomic) QBMulticastDelegate <QMChatServiceDelegate> *multicastDelegate;
@property (weak, nonatomic) id<QMChatServiceCacheDelegate> cahceDelegate;

@property (strong, nonatomic) QMDialogsMemoryStorage *dialogsMemoryStorage;
@property (strong, nonatomic) QMMessagesMemoryStorage *messagesMemoryStorage;

@property (copy, nonatomic) void(^chatSuccessBlock)(NSError *error);
@property (strong, nonatomic) NSTimer *presenceTimer;

@end

@implementation QMChatService

- (void)dealloc {
    NSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
    self.dialogsMemoryStorage = nil;
    
    NSAssert(![QBChat.instance isLoggedIn], @"Need update this case");
    [self.presenceTimer invalidate];
    [QBChat.instance removeDelegate:self];
}

#pragma mark - Configure

- (id)initWithServiceDataDelegate:(id<QMServiceDataDelegate>)serviceDataDelegate {
    
    self = [super initWithServiceDataDelegate:serviceDataDelegate];
    
    if (self) {
        
        [self defaultInit];
    };
    
    return self;
}

- (instancetype)initWithServiceDataDelegate:(id<QMServiceDataDelegate>)serviceDataDelegate
                              cacheDelegate:(id<QMChatServiceCacheDelegate>)cacheDelegate {
    
    self = [super initWithServiceDataDelegate:serviceDataDelegate];
    if (self) {
        
        self.cahceDelegate = cacheDelegate;
        
        [self defaultInit];
        [self loadCachedDialogs];
        
    }
    return self;
}

- (void)defaultInit {
    
    self.multicastDelegate = (id<QMChatServiceDelegate>)[[QBMulticastDelegate alloc] init];
    self.dialogsMemoryStorage = [[QMDialogsMemoryStorage alloc] init];
    
    [QBChat.instance addDelegate:self];
}

#pragma mark - Load cached data

- (void)loadCachedDialogs {
    
    __weak __typeof(self)weakSelf = self;
    dispatch_queue_t queue = dispatch_queue_create("com.q-municate.loadChatCacheQueue", DISPATCH_QUEUE_SERIAL);
    // Load dialogs from cahce
    dispatch_async(queue, ^{
        
        if ([self.cahceDelegate respondsToSelector:@selector(cachedDialogs:)]) {
            
            dispatch_semaphore_t sem = dispatch_semaphore_create(0);
            
            [self.cahceDelegate cachedDialogs:^(NSArray *collection) {
                
                [weakSelf.dialogsMemoryStorage addChatDialogs:collection andJoin:NO];
                dispatch_semaphore_signal(sem);
            }];
            
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
            
        }
    });
    // Notifiy about load dialogs from cahce
    dispatch_async(queue, ^{
        
        if ([self.multicastDelegate respondsToSelector:@selector(chatServiceDidLoadDialogsFromCache)]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.multicastDelegate chatServiceDidLoadDialogsFromCache];
            });
        }
    });
}

- (void)loadCahcedMessagesWithDialogID:(NSString *)dialogID {
    
    __weak __typeof(self)weakSelf = self;
    dispatch_queue_t queue = dispatch_queue_create("com.q-municate.loadChatCacheQueue", DISPATCH_QUEUE_SERIAL);
    // Load messages from cahce
    dispatch_async(queue, ^{
        
        if ([self.cahceDelegate respondsToSelector:@selector(cachedMessagesWithDialogID:block:)]) {
            
            dispatch_semaphore_t sem = dispatch_semaphore_create(0);
            
            [self.cahceDelegate cachedMessagesWithDialogID:dialogID block:^(NSArray *collection) {
                
                [weakSelf.messagesMemoryStorage replaceMessages:collection
                                                    forDialogID:dialogID];
                dispatch_semaphore_signal(sem);
            }];
            
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
            
        }
    });
    
    // Notifiy about load messages from cahce
    dispatch_async(queue, ^{
        
        if ([self.multicastDelegate respondsToSelector:@selector(chatServiceDidLoadMessagesFromCacheForDialogID:)]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.multicastDelegate chatServiceDidLoadMessagesFromCacheForDialogID:dialogID];
            });
        }
    });
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

- (void)chatDidFailWithStreamError:(NSError *)error {
    
    if (self.chatSuccessBlock){
        self.chatSuccessBlock(error);
        self.chatSuccessBlock = nil;
    }
}

#pragma mark Handle messadges (QBChatDelegate)

- (void)chatRoomDidReceiveMessage:(QBChatMessage *)message
                      fromRoomJID:(NSString *)roomJID {
    
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
    [NSTimer scheduledTimerWithTimeInterval:kQMPresenceTimeIntervalInSec
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
            
            //Update chat dialog from memroy storage
            QBChatDialog *chatDialogToUpdate = [self.dialogsMemoryStorage chatDialogWithID:message.cParamDialogID];
            chatDialogToUpdate.lastMessageText = message.encodedText;
            chatDialogToUpdate.lastMessageDate = [NSDate dateWithTimeIntervalSince1970:message.cParamDateSent.doubleValue];
            chatDialogToUpdate.unreadMessagesCount++;
            //Add message in memory storage
            [self.messagesMemoryStorage addMessage:message
                                       forDialogID:message.cParamDialogID];
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatServiceDidAddMessageToHistory:forDialog:)]) {
                
                [self.multicastDelegate chatServiceDidAddMessageToHistory:message
                                                                forDialog:chatDialogToUpdate];
            }
        }
    }
    else if (message.cParamNotificationType == QMMessageNotificationTypeCreateGroupDialog) {
        
        QBChatDialog *newChatDialog =
        [message chatDialogFromCustomParameters];
        
        [self.dialogsMemoryStorage addChatDialog:newChatDialog
                                         andJoin:YES];
        
        if ([self.multicastDelegate respondsToSelector:@selector(chatServiceDidReceiveNotificationMessage:createDialog:)]) {
            
            [self.multicastDelegate chatServiceDidReceiveNotificationMessage:message
                                                                createDialog:newChatDialog];
        }
    }
    else if (message.cParamNotificationType == QMMessageNotificationTypeUpdateGroupDialog) {
        
        QBChatDialog *chatDialogToUpdate =
        [self.dialogsMemoryStorage chatDialogWithID:message.cParamDialogID];
        
        chatDialogToUpdate.name = message.cParamDialogRoomName;
        
        if ([self.multicastDelegate respondsToSelector:@selector(chatServiceDidReceiveNotificationMessage:updateDialog:)]) {
            
            [self.multicastDelegate chatServiceDidReceiveNotificationMessage:message
                                                                updateDialog:chatDialogToUpdate];
        }
    }
}

#pragma mark - Dialog history

- (void)fetchAllDialogs:(void(^)(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs))completion {
    
    __weak __typeof(self)weakSelf = self;
    [QBRequest dialogsWithSuccessBlock:^(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs) {
        
        [weakSelf.dialogsMemoryStorage addChatDialogs:dialogObjects
                                              andJoin:YES];
        
        if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogs:)]) {
            
            [weakSelf.multicastDelegate chatService:weakSelf
                                  didAddChatDialogs:dialogObjects];
        }
        
        if (completion) {
            completion(response, dialogObjects, dialogsUsersIDs);
        }
        
    } errorBlock:^(QBResponse *response) {
        
        if (completion) {
            completion(response, nil, nil);
        }
    }];
}

#pragma mark - Create Private/Group dialog

- (void)createPrivateChatDialogIfNeededWithOpponent:(QBUUser *)opponent
                                         completion:(void(^)(QBResponse *response, QBChatDialog *createdDialo))completion {
    
    QBChatDialog *dialog = [self.dialogsMemoryStorage privateChatDialogWithOpponentID:opponent.ID];
    
    dialog = nil;
    
    if (!dialog) {
        
        QBChatDialog *chatDialog = [[QBChatDialog alloc] init];
        chatDialog.type = QBChatDialogTypePrivate;
        chatDialog.occupantIDs = @[@(opponent.ID)];
        
        __weak __typeof(self)weakSelf = self;
        
        [QBRequest createDialog:chatDialog
                   successBlock:^(QBResponse *response, QBChatDialog *createdDialog) {
            
            [self.dialogsMemoryStorage addChatDialog:createdDialog
                                             andJoin:YES];
            
            [weakSelf sendNotificationWithType:QMMessageNotificationTypeCreateGroupDialog
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
    [QBRequest createDialog:chatDialog
               successBlock:^(QBResponse *response, QBChatDialog *createdDialog)
     {
         [self.dialogsMemoryStorage addChatDialog:createdDialog
                                          andJoin:YES];

         [weakSelf sendNotificationWithType:QMMessageNotificationTypeCreateGroupDialog
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
    
    QBUpdateDialogParameters *updateParameters =
    [QBUpdateDialogParameters updateDialogWithDialogID:chatDialog.ID
                                         dialogNewName:dialogName];
    
    [QBRequest updateDialog:updateParameters
               successBlock:^(QBResponse *response, QBChatDialog *updatedDialog)
     {
      
         [self.dialogsMemoryStorage addChatDialog:updatedDialog
                                          andJoin:NO];
         
         chatDialog.name = dialogName;
         [weakSelf sendNotificationWithType:QMMessageNotificationTypeUpdateGroupDialog
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
    
    QBUpdateDialogParameters *updateParams =
    [QBUpdateDialogParameters updateDialogWithDialogID:chatDialog.ID
                                        addedOccupants:occupantsToJoinIDs
                                      removedOccupants:nil];
    
    [QBRequest updateDialog:updateParams
               successBlock:^(QBResponse *response, QBChatDialog *updatedDialog)
     {
         
         [self.dialogsMemoryStorage addChatDialog:updatedDialog
                                          andJoin:NO];
         
         [weakSelf sendNotificationWithType:QMMessageNotificationTypeUpdateGroupDialog
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

#pragma mark - Messages histroy

- (void)fetchMessageWithChatDialogID:(NSString *)chatDialogID
                        complete:(void(^)(QBResponse *response, NSArray *messages))completion {
    
    [self loadCahcedMessagesWithDialogID:chatDialogID];
    
    [QBRequest messagesWithDialogID:chatDialogID
                       successBlock:^(QBResponse *response, NSArray *messages)
     {
         [self.messagesMemoryStorage replaceMessages:messages
                                         forDialogID:chatDialogID];
         
     } errorBlock:^(QBResponse *response) {
         
         completion(response, nil);
     }];
}

#pragma mark - Send messages

- (void)sendMessage:(QBChatMessage *)message
       withDialogID:(NSString *)dialogID
      saveToHistory:(BOOL)save
         completion:(void(^)(NSError *error))completion {
    
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
    
    QBUUser *currentUser = [self.serviceDataDelegate serviceDataCurrentProfile];
    
    void (^finish)(QBChatMessage *historyMessage) = ^(QBChatMessage *historyMessage){
        
        historyMessage.senderID = currentUser.ID;
        
        //        [weakSelf addMessageToHistory:historyMessage withDialogID:dialog.ID];
        dialog.lastMessageText = historyMessage.encodedText;
        dialog.lastMessageDate = historyMessage.datetime;
        
        //        [weakSelf.multicastDelegate chatServiceDidDialogsHistoryUpdated];
        
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
