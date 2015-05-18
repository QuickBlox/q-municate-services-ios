//
//  QMChatDialogsService.m
//  Q-municate
//
//  Created by Andrey Ivanov on 02.07.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMChatService.h"
#import "QBChatMessage+TextEncoding.h"
#import "NSString+GTMNSStringHTMLAdditions.h"
#import "QBChatMessage+QMCustomParameters.h"

const NSTimeInterval kQMPresenceTimeIntervalInSec = 45;
const char *kChatCacheQueue = "com.q-municate.chatCacheQueue";

@interface QMChatService() <QBChatDelegate>

@property (strong, nonatomic) QBMulticastDelegate <QMChatServiceDelegate> *multicastDelegate;
@property (weak, nonatomic) id <QMChatServiceCacheDelegate> cahceDelegate;
@property (strong, nonatomic) QMDialogsMemoryStorage *dialogsMemoryStorage;
@property (strong, nonatomic) QMMessagesMemoryStorage *messagesMemoryStorage;
@property (strong, nonatomic, readonly) NSNumber *dateSendTimeInterval;

@property (copy, nonatomic) void(^chatSuccessBlock)(NSError *error);

@property (strong, nonatomic) NSTimer *presenceTimer;

@end

@implementation QMChatService

@dynamic dateSendTimeInterval;

- (void)dealloc {
    
    NSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
    
    [self.presenceTimer invalidate];
    [QBChat.instance removeDelegate:self];
}

#pragma mark - Configure

- (instancetype)initWithServiceManager:(id<QMServiceManagerProtocol>)serviceManager
                         cacheDelegate:(id<QMChatServiceCacheDelegate>)cacheDelegate {
    
    self = [super initWithServiceManager:serviceManager];
    
    if (self) {
        
        self.cahceDelegate = cacheDelegate;
        [self loadCachedDialogs];
    }
    
    return self;
}

- (void)serviceWillStart {
    
    self.multicastDelegate = (id<QMChatServiceDelegate>)[[QBMulticastDelegate alloc] init];
    self.dialogsMemoryStorage = [[QMDialogsMemoryStorage alloc] init];
    self.messagesMemoryStorage = [[QMMessagesMemoryStorage alloc] init];
    
    [QBChat.instance addDelegate:self];
}

#pragma mark - Getters

- (NSNumber *)dateSendTimeInterval {
    
    return  @((NSInteger)CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970);
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatServiceDidLoadDialogsFromCache)]) {
                [self.multicastDelegate chatServiceDidLoadDialogsFromCache];
            }
        });
    });
}

- (void)loadCahcedMessagesWithDialogID:(NSString *)dialogID {
    
    __weak __typeof(self)weakSelf = self;
    dispatch_queue_t queue = dispatch_queue_create(kChatCacheQueue, DISPATCH_QUEUE_SERIAL);
    // Load messages from cahce
    dispatch_async(queue, ^{
        
        if ([self.cahceDelegate respondsToSelector:@selector(cachedMessagesWithDialogID:block:)]) {
            
            dispatch_semaphore_t sem = dispatch_semaphore_create(0);
            
            [self.cahceDelegate cachedMessagesWithDialogID:dialogID block:^(NSArray *collection) {
                
                [weakSelf.messagesMemoryStorage replaceMessages:collection forDialogID:dialogID];
                dispatch_semaphore_signal(sem);
            }];
            
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        }
    });
    
    // Notifiy about load messages from cahce
    dispatch_async(queue, ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatServiceDidLoadMessagesFromCacheForDialogID:)]) {
                [self.multicastDelegate chatServiceDidLoadMessagesFromCacheForDialogID:dialogID];
            }
        });
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
    
    [self sendPresence:nil];
    
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

#pragma mark Handle messages (QBChatDelegate)

- (void)chatRoomDidReceiveMessage:(QBChatMessage *)message fromRoomJID:(NSString *)roomJID {
    
    [self handleChatMessage:message];
}

- (void)chatDidReceiveMessage:(QBChatMessage *)message {
    
    [self handleChatMessage:message];
}

- (void)chatRoomDidEnter:(QBChatRoom *)room {
    
}

- (void)chatRoomDidNotEnter:(NSString *)roomName error:(NSError *)error {
    
}

#pragma mark - Chat Login/Logout

- (void)logIn:(void(^)(NSError *error))completion {
    
    BOOL isAutorized = self.serviceManager.isAutorized;
    NSAssert(isAutorized, @"User muste be autorized");
    
    self.chatSuccessBlock = completion;
    QBUUser *user = self.serviceManager.currentUser;
    
    if (QBChat.instance.isLoggedIn) {
        
        self.chatSuccessBlock(nil);
    }
    else {
        
        [QBChat.instance loginWithUser:user];
        
        QBChat.instance.autoReconnectEnabled = YES;
        QBChat.instance.streamManagementEnabled = YES;
    }
}

- (void)logoutChat {
    
    if (QBChat.instance.isLoggedIn) {
        [QBChat.instance logout];
    }
}

#pragma mark - Presence

- (void)startSendPresence {
    
    NSAssert(!self.presenceTimer, @"Must be nil");
    
    self.presenceTimer =
    [NSTimer scheduledTimerWithTimeInterval:kQMPresenceTimeIntervalInSec
                                     target:self
                                   selector:@selector(sendPresence:)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)sendPresence:(NSTimer *)timer {
    
    [QBChat.instance sendPresence];
}

- (void)stopSendPresence {
    
    [self.presenceTimer invalidate];
    self.presenceTimer = nil;
}

#pragma mark - Handle Chat messages

- (void)handleChatMessage:(QBChatMessage *)message {
    
    NSString *dialogID = message.dialog.ID;
    
    NSAssert(dialogID, @"Need update this case");
    
    if (message.messageType == QMMessageTypeText) {
        
        if (message.recipientID != message.senderID) {
            
            //Update chat dialog from memroy storage
            
            QBChatDialog *chatDialogToUpdate = [self.dialogsMemoryStorage chatDialogWithID:dialogID];
            chatDialogToUpdate.lastMessageText = message.encodedText;
            chatDialogToUpdate.lastMessageDate = [NSDate dateWithTimeIntervalSince1970:message.customDateSent.doubleValue];
            chatDialogToUpdate.unreadMessagesCount++;
            //Add message in memory storage
            [self.messagesMemoryStorage addMessage:message forDialogID:dialogID];
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatServiceDidAddMessageToHistory:forDialogID:)]) {
                [self.multicastDelegate chatServiceDidAddMessageToHistory:message forDialogID:dialogID];
            }
        }
    }
    else if (message.messageType == QMMessageTypeCreateGroupDialog) {
        
        QBChatDialog *newChatDialog = [message dialog];
        
        [self.dialogsMemoryStorage addChatDialog:newChatDialog andJoin:YES];
        
        if ([self.multicastDelegate respondsToSelector:@selector(chatServiceDidReceiveNotificationMessage:createDialog:)]) {
            [self.multicastDelegate chatServiceDidReceiveNotificationMessage:message createDialog:newChatDialog];
        }
    }
    else if (message.messageType == QMMessageTypeUpdateGroupDialog) {
        
        QBChatDialog *chatDialogToUpdate = [self.dialogsMemoryStorage chatDialogWithID:dialogID];
        
        chatDialogToUpdate.name = message.dialog.name;
        chatDialogToUpdate.photo = message.dialog.photo;
        
        if ([self.multicastDelegate respondsToSelector:@selector(chatServiceDidReceiveNotificationMessage:updateDialog:)]) {
            [self.multicastDelegate chatServiceDidReceiveNotificationMessage:message updateDialog:chatDialogToUpdate];
        }
    }
}

#pragma mark - Dialog history

- (void)dialogs:(void(^)(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs))completion {
    
    __weak __typeof(self)weakSelf = self;
    [QBRequest dialogsWithSuccessBlock:^(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs) {
        
        [weakSelf.dialogsMemoryStorage addChatDialogs:dialogObjects andJoin:NO];
        
        if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogs:)]) {
            [weakSelf.multicastDelegate chatService:weakSelf didAddChatDialogs:dialogObjects];
        }
        
        if (completion) {
            completion(response, dialogObjects, dialogsUsersIDs);
        }
        
    } errorBlock:^(QBResponse *response) {
        
        [weakSelf.serviceManager handleErrorResponse:response];
        
        if (completion) {
            completion(response, nil, nil);
        }
    }];
}

- (void)fetchMessageWithDialogID:(NSString *)chatDialogId
                        complete:(void(^)(QBResponse *response, NSArray *messages))completion {
    
}

#pragma mark - Create Private/Group dialog

- (void)createPrivateChatDialogWithOpponent:(QBUUser *)opponent
                                 completion:(void(^)(QBResponse *response, QBChatDialog *createdDialo))completion {
    
    QBChatDialog *dialog = [self.dialogsMemoryStorage privateChatDialogWithOpponentID:opponent.ID];
    
    if (!dialog) {
        
        QBChatDialog *chatDialog = [[QBChatDialog alloc] init];
        chatDialog.type = QBChatDialogTypePrivate;
        chatDialog.occupantIDs = @[@(opponent.ID)];
        
        __weak __typeof(self)weakSelf = self;
        
        [QBRequest createDialog:chatDialog successBlock:^(QBResponse *response, QBChatDialog *createdDialog) {
            
            [weakSelf.dialogsMemoryStorage addChatDialog:createdDialog andJoin:YES];
            //Notify about create new dialog
            if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialog:)]) {
                [weakSelf.multicastDelegate chatService:weakSelf didAddChatDialog:createdDialog];
            }
            
            if (completion) {
                completion(response, createdDialog);
            }
            
        } errorBlock:^(QBResponse *response) {
            
            [weakSelf.serviceManager handleErrorResponse:response];
            
            if (completion) {
                completion(response, nil);
            }
        }];
        
    }
    else {
        
        if (completion) {
            completion(nil, dialog);
        }
    }
}

- (void)createGroupChatDialogWithName:(NSString *)name photo:(NSString *)photo occupants:(NSArray *)occupants
                           completion:(void(^)(QBResponse *response, QBChatDialog *createdDialog))completion {
    
    NSMutableSet *occupantIDs = [NSMutableSet set];
    
    for (QBUUser *user in occupants) {
        [occupantIDs addObject:@(user.ID)];
    }
    
    QBChatDialog *chatDialog = [[QBChatDialog alloc] init];
    chatDialog.name = name;
    chatDialog.photo = photo;
    chatDialog.occupantIDs = occupantIDs.allObjects;
    chatDialog.type = QBChatDialogTypeGroup;
    
    __weak __typeof(self)weakSelf = self;
    [QBRequest createDialog:chatDialog successBlock:^(QBResponse *response, QBChatDialog *createdDialog) {
        
        [weakSelf.dialogsMemoryStorage addChatDialog:createdDialog andJoin:YES];
        
        if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogs:)]) {
            [weakSelf.multicastDelegate chatService:weakSelf didAddChatDialog:createdDialog];
        }
        
        if (completion) {
            completion(response, createdDialog);
        }
        
    } errorBlock:^(QBResponse *response) {
        
        [weakSelf.serviceManager handleErrorResponse:response];
        
        if (completion) {
            completion(response, nil);
        }
    }];
}

#pragma mark - Edit dialog methods

- (void)changeChatName:(NSString *)dialogName forChatDialog:(QBChatDialog *)chatDialog
            completion:(void(^)(QBResponse *response, QBChatDialog *updatedDialog))completion {
    
    chatDialog.name = dialogName;
    
    __weak __typeof(self)weakSelf = self;
    [QBRequest updateDialog:chatDialog
               successBlock:^(QBResponse *response, QBChatDialog *updatedDialog) {
        
        [weakSelf.dialogsMemoryStorage addChatDialog:updatedDialog andJoin:NO];
        
        if (completion) {
            completion(response, updatedDialog);
        }
        
    } errorBlock:^(QBResponse *response) {
        
        [weakSelf.serviceManager handleErrorResponse:response];
        
        if (completion) {
            completion(response, nil);
        }
    }];
}

- (void)joinOccupantsWithIDs:(NSArray *)ids toChatDialog:(QBChatDialog *)chatDialog
                  completion:(void(^)(QBResponse *response, QBChatDialog *updatedDialog))completion {
    
    __weak __typeof(self)weakSelf = self;

    [QBRequest updateDialog:chatDialog successBlock:^(QBResponse *response, QBChatDialog *updatedDialog) {
        
        [weakSelf.dialogsMemoryStorage addChatDialog:updatedDialog andJoin:NO];
        
        //        [weakSelf sendNotificationWithType:QMNotificationTypeUpdateGroupDialog
        //                                      text:@"Added new users"
        //                              toRecipients:ids
        //                                chatDialog:updatedDialog];
        
        if (completion) {
            completion(response, updatedDialog);
        }
        
    } errorBlock:^(QBResponse *response) {
        
        [weakSelf.serviceManager handleErrorResponse:response];
        
        if (completion) {
            completion(response, nil);
        }
    }];
}

#pragma mark - Messages histroy

- (void)messageWithChatDialogID:(NSString *)chatDialogID completion:(void(^)(QBResponse *response, NSArray *messages))completion {
    
    [self loadCahcedMessagesWithDialogID:chatDialogID];
    
    __weak __typeof(self) weakSelf = self;
    [QBRequest messagesWithDialogID:chatDialogID successBlock:^(QBResponse *response, NSArray *messages) {
        
        [weakSelf.messagesMemoryStorage replaceMessages:messages forDialogID:chatDialogID];
        
        if ([self.multicastDelegate respondsToSelector:@selector(chatServiceDidAddMessagesToHistroy:forDialogID:)]) {
            [self.multicastDelegate chatServiceDidAddMessagesToHistroy:messages forDialogID:chatDialogID];
        }
        
        if (completion) {
            completion(response, messages);
        }
        
    } errorBlock:^(QBResponse *response) {
        
        [weakSelf.serviceManager handleErrorResponse:response];
        
        if (completion) {
            completion(response, nil);
        }
    }];
}

#pragma mark - Send messages

- (void)sendMessage:(QBChatMessage *)message toDialog:(QBChatDialog *)dialog type:(QMMessageType)type save:(BOOL)save completion:(void(^)(NSError *error))completion {
    //Set custom parametes @see 
    [message updateCustomParametersWithDialog:dialog];
    message.messageType = type;
    message.customDateSent = self.dateSendTimeInterval;
    message.text = [message.text gtm_stringByEscapingForHTML];
    
    if (save) {
        
        message.saveToHistory = @"1";
    }
    
    QBUUser *currentUser = self.serviceManager.currentUser;
    
    void (^finish)(QBChatMessage *historyMessage) = ^(QBChatMessage *historyMessage){
        
        historyMessage.senderID = currentUser.ID;
        
        dialog.lastMessageText = historyMessage.encodedText;
        dialog.lastMessageDate = historyMessage.dateSent;
        
        [self.messagesMemoryStorage addMessage:historyMessage forDialogID:dialog.ID];
        
        if ([self.multicastDelegate respondsToSelector:@selector(chatServiceDidAddMessageToHistory:forDialogID:)]) {
            [self.multicastDelegate chatServiceDidAddMessageToHistory:historyMessage forDialogID:dialog.ID];
        }
        
        if (completion) {
            completion(nil);
        }
    };
    
    switch (dialog.type) {
            
        case QBChatDialogTypePrivate: {
            //Only p2p
            message.senderID = currentUser.ID;
            message.recipientID = dialog.recipientID;
            message.markable = YES;
            
            [QBChat.instance sendMessage:message sentBlock:^(NSError *error) {
                
                if (!error) {
                    
                    finish(message);
                }
            }];
            
        }
            break;
            
        case QBChatDialogTypeGroup: {
            
            [[QBChat instance] sendChatMessage:message toRoom:dialog.chatRoom];
        }
            break;
            
        case QBChatDialogTypePublicGroup: {
            
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - QMMemoryStorageProtocol

- (void)free {
    
    [self.messagesMemoryStorage free];
    [self.dialogsMemoryStorage free];
}

@end
