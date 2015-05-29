//
//  QMChatService.m
//  Q-municate
//
//  Created by Andrey Ivanov on 02.07.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMChatService.h"
#import "QBChatMessage+TextEncoding.h"
#import "NSString+GTMNSStringHTMLAdditions.h"
#import "QBChatMessage+QMCustomParameters.h"

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

- (instancetype)initWithServiceManager:(id<QMServiceManagerProtocol>)serviceManager cacheDelegate:(id<QMChatServiceCacheDelegate>)cacheDelegate {
    
    self = [super initWithServiceManager:serviceManager];
    
    if (self) {
        
        self.cahceDelegate = cacheDelegate;
        [self loadCachedDialogs];
		
		self.presenceTimerInterval = 45.0;
		self.automaticallySendPresences = YES;
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
    
    return @((NSInteger)CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970);
}

#pragma mark - Load cached data

- (void)loadCachedDialogs {
    
    __weak __typeof(self)weakSelf = self;
    
    if ([self.cahceDelegate respondsToSelector:@selector(cachedDialogs:)]) {
        
        [self.cahceDelegate cachedDialogs:^(NSArray *collection) {
            
            [weakSelf.dialogsMemoryStorage addChatDialogs:collection andJoin:NO];
            
            if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogsToMemoryStorage:)]) {
                [weakSelf.multicastDelegate chatService:weakSelf didAddChatDialogsToMemoryStorage:collection];
            }
        }];
    }
}

- (void)loadCahcedMessagesWithDialogID:(NSString *)dialogID {
    
    if ([self.cahceDelegate respondsToSelector:@selector(cachedMessagesWithDialogID:block:)]) {
        
        __weak __typeof(self)weakSelf = self;
        [self.cahceDelegate cachedMessagesWithDialogID:dialogID block:^(NSArray *collection) {
            
            [weakSelf.messagesMemoryStorage replaceMessages:collection forDialogID:dialogID];
            
            if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddMessagesToMemoryStorage:forDialogID:)]) {
                [weakSelf.multicastDelegate chatService:weakSelf didAddMessagesToMemoryStorage:collection forDialogID:dialogID];
            }
        }];
    }
}

#pragma mark - Add / Remove Multicast delegate

- (void)addDelegate:(id<QMChatServiceDelegate>)delegate {
    
    [self.multicastDelegate addDelegate:delegate];
}

- (void)removeDelegate:(id<QMChatServiceDelegate>)delegate{
    
    [self.multicastDelegate removeDelegate:delegate];
}

#pragma mark - QBChatDelegate

- (void)chatDidLogin {
	if (self.automaticallySendPresences){
		[self startSendPresence];
	}
	
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
	
	[self stopSendPresence];
}

#pragma mark Handle messages (QBChatDelegate)

- (void)chatRoomDidReceiveMessage:(QBChatMessage *)message fromRoomJID:(NSString *)roomJID {
    
    [self handleChatMessage:message];
}

- (void)chatDidReceiveMessage:(QBChatMessage *)message {
    
    [self handleChatMessage:message];
}

#pragma mark - Chat Login/Logout

- (void)logIn:(void(^)(NSError *error))completion {
    
    BOOL isAutorized = self.serviceManager.isAutorized;
    NSAssert(isAutorized, @"User must be autorized");
    
    self.chatSuccessBlock = completion;
    QBUUser *user = self.serviceManager.currentUser;
    
    if (QBChat.instance.isLoggedIn) {
        
        self.chatSuccessBlock(nil);
    }
    else {
        
        QBChat.instance.autoReconnectEnabled = YES;
        QBChat.instance.streamManagementEnabled = YES;
        [QBChat.instance loginWithUser:user];
        
    }
}

- (void)logoutChat {

	[self stopSendPresence];
	
    if (QBChat.instance.isLoggedIn) {
        [QBChat.instance logout];
    }
}

#pragma mark - Presence

- (void)startSendPresence {
	
	[self sendPresence:nil];
	
    self.presenceTimer =
    [NSTimer scheduledTimerWithTimeInterval:self.presenceTimerInterval
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
    
    NSAssert(message.dialogID, @"Need update this case");
    
    if (message.messageType == QMMessageTypeText) {
        
        if (message.recipientID != message.senderID) {
            
            //Update chat dialog in memroy storage
            QBChatDialog *chatDialogToUpdate = [self.dialogsMemoryStorage chatDialogWithID:message.dialogID];
            chatDialogToUpdate.lastMessageText = message.encodedText;
            chatDialogToUpdate.lastMessageDate = [NSDate dateWithTimeIntervalSince1970:message.customDateSent.doubleValue];
            chatDialogToUpdate.unreadMessagesCount++;
            //Add message in memory storage
            [self.messagesMemoryStorage addMessage:message forDialogID:message.dialogID];
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatService:didAddMessageToMemoryStorage:forDialogID:)]) {
                [self.multicastDelegate chatService:self didAddMessageToMemoryStorage:message forDialogID:message.dialogID];
            }
        }
    }
    else if (message.messageType == QMMessageTypeCreateGroupDialog) {
        
        [self.dialogsMemoryStorage addChatDialog:message.dialog andJoin:YES];
        
        if ([self.multicastDelegate respondsToSelector:@selector(chatService:didReceiveNotificationMessage:createDialog:)]) {
            [self.multicastDelegate chatService:self didReceiveNotificationMessage:message createDialog:message.dialog];
        }
    }
    else if (message.messageType == QMMessageTypeUpdateGroupDialog) {
        
        QBChatDialog *chatDialogToUpdate = [self.dialogsMemoryStorage chatDialogWithID:message.dialogID];
        
        chatDialogToUpdate.name = message.dialog.name;
        chatDialogToUpdate.photo = message.dialog.photo;
        
        if ([self.multicastDelegate respondsToSelector:@selector(chatService:didReceiveNotificationMessage:createDialog:)]) {
            [self.multicastDelegate chatService:self didReceiveNotificationMessage:message createDialog:message.dialog];
        }
    }
}

#pragma mark - Dialog history

- (void)allDialogsWithPageLimit:(NSUInteger)limit
                interationBlock:(void(^)(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs, BOOL *stop))interationBlock
                     completion:(void(^)(QBResponse *response))completion {
    
    __weak __typeof(self)weakSelf = self;
    
    __block QBResponsePage *responsePage = [QBResponsePage responsePageWithLimit:limit];
    __block BOOL cancel = NO;

     __block dispatch_block_t t_request;
    
    dispatch_block_t request = [^{
        
        [QBRequest dialogsForPage:responsePage extendedRequest:nil successBlock:^(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs, QBResponsePage *page) {
            
            [weakSelf.dialogsMemoryStorage addChatDialogs:dialogObjects andJoin:NO];
            
            if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogsToMemoryStorage:)]) {
                [weakSelf.multicastDelegate chatService:weakSelf didAddChatDialogsToMemoryStorage:dialogObjects];
            }
            
            responsePage.skip += dialogObjects.count;
            
            if (page.totalEntries <= responsePage.skip) {
                cancel = YES;
            }
            
            interationBlock(response, dialogObjects, dialogsUsersIDs, &cancel);
            
            if (!cancel) {
                
                t_request();
            }
            else {
                
                if (completion) {
                    completion(response);
                }
            }
            
        } errorBlock:^(QBResponse *response) {
            
            [weakSelf.serviceManager handleErrorResponse:response];
            
            if (completion) {
                completion(response);
            }
        }];
        
    } copy];
    
    t_request = request;
    request();
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
            if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogToMemoryStorage:)]) {
                [weakSelf.multicastDelegate chatService:weakSelf didAddChatDialogToMemoryStorage:createdDialog];
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
		NSAssert([user isKindOfClass:[QBUUser class]], @"occupants must be an array of QBUUser instances");
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
        
        if ([weakSelf.multicastDelegate respondsToSelector:@selector(chatService:didAddChatDialogToMemoryStorage:)]) {
            [weakSelf.multicastDelegate chatService:weakSelf didAddChatDialogToMemoryStorage:createdDialog];
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

- (void)changeDialogName:(NSString *)dialogName forChatDialog:(QBChatDialog *)chatDialog
              completion:(void(^)(QBResponse *response, QBChatDialog *updatedDialog))completion {
    
    chatDialog.name = dialogName;
    
    __weak __typeof(self)weakSelf = self;
    [QBRequest updateDialog:chatDialog successBlock:^(QBResponse *response, QBChatDialog *updatedDialog) {
        
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
        
        if ([self.multicastDelegate respondsToSelector:@selector(chatService:didAddMessagesToMemoryStorage:forDialogID:)]) {
            [self.multicastDelegate chatService:weakSelf didAddMessagesToMemoryStorage:messages forDialogID:chatDialogID];
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
    
    [message updateCustomParametersWithDialog:dialog];
    message.messageType = type;
    message.customDateSent = self.dateSendTimeInterval;
    message.text = [message.text gtm_stringByEscapingForHTML];
    
    if (save) {
        message.saveToHistory = @"1";
    }
    
    QBUUser *currentUser = self.serviceManager.currentUser;
    
    if (dialog.type == QBChatDialogTypePrivate) {
        
        message.senderID = currentUser.ID;
        message.recipientID = dialog.recipientID;
        message.markable = YES;
    }
    
    [dialog sendMessage:message sentBlock:^(NSError *error) {
        
        if (!error) {
            
            message.senderID = currentUser.ID;
            
            dialog.lastMessageText = message.encodedText;
            dialog.lastMessageDate = message.dateSent;
            
            [self.messagesMemoryStorage addMessage:message forDialogID:dialog.ID];
            
            if ([self.multicastDelegate respondsToSelector:@selector(chatService:didAddMessageToMemoryStorage:forDialogID:)]) {
                [self.multicastDelegate chatService:self didAddMessageToMemoryStorage:message forDialogID:dialog.ID];
            }
        }
        
        if (completion) {
            completion(error);
        }
    }];
}

#pragma mark - QMMemoryStorageProtocol

- (void)free {
    
    [self.messagesMemoryStorage free];
    [self.dialogsMemoryStorage free];
}

@end
