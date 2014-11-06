//
//  QMDialogsMemoryStorage.m
//  Q-municate
//
//  Created by Andrey on 03.11.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMDialogsMemoryStorage.h"
#import "QBChatAbstractMessage+CustomParameters.h"

@interface QMDialogsMemoryStorage()

@property (strong, nonatomic) NSMutableDictionary *dialogs;
@property (strong, nonatomic) NSMutableDictionary *messages;

@end

@implementation QMDialogsMemoryStorage

- (void)dealloc {
    
    [self.messages removeAllObjects];
    [self.dialogs removeAllObjects];
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        self.dialogs = [NSMutableDictionary dictionary];
        self.messages = [NSMutableDictionary dictionary];
    }
    return self;
}

- (QBChatDialog *)chatDialogWithID:(NSString *)dialogID {
    return self.dialogs[dialogID];
}

- (QBChatDialog *)privateChatDialogWithOpponentID:(NSUInteger)opponentID {
    
    NSArray *allDialogs = [self unreadDialogs];
    
    NSPredicate *predicate =
    [NSPredicate predicateWithFormat:@"SELF.type == %d AND SUBQUERY(SELF.occupantIDs, $userID, $userID == %@).@count > 0",
     QBChatDialogTypePrivate, @(opponentID)];
    
    NSArray *result = [allDialogs filteredArrayUsingPredicate:predicate];
    QBChatDialog *dialog = result.firstObject;
    
    return dialog;
}

- (QBChatDialog *)chatDialogWithChatRoom:(QBChatRoom *)chatRoom {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.chatRoom == %@", chatRoom];
    NSArray *filtered = [self.dialogs.allValues filteredArrayUsingPredicate:predicate];

    NSAssert(filtered.count == 1, @"Array count must be 1");
    
    return filtered.firstObject;
}

- (void)addDialogsToHistory:(NSArray *)dialogs joinIfNeeded:(BOOL)join {
    
    if (dialogs.count > 0) {
        
        for (QBChatDialog *chatDialog in dialogs) {
            
            self.dialogs[chatDialog.ID] = chatDialog;
            
            if (join) {
                
                if (!chatDialog.chatRoom.isJoined) {
                    [chatDialog.chatRoom joinRoomWithHistoryAttribute:@{@"maxstanzas": @"0"}];
                }
            }
        }
        
//        if ([self.multicastDelegate respondsToSelector:@selector(chatServiceDidDialogsHistoryUpdated)]) {
//            [self.multicastDelegate chatServiceDidDialogsHistoryUpdated];
//        }
    }
}

- (void)leaveFromRooms {
    
    for (QBChatDialog *chatDialog in self.dialogs.allValues) {
        
        if (chatDialog.chatRoom.isJoined) {
            [chatDialog .chatRoom leaveRoom];
        }
        else {
            NSLog(@"Check this case");
        }
    }
}

- (QBChatDialog *)chatDialogWithRoomName:(NSString *)roomName {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.chatRoom.name"];
    QBChatDialog *chatDialog = [self.dialogs.allValues filteredArrayUsingPredicate:predicate].firstObject;
    
    return chatDialog;
}

- (NSArray *)unsortedDialogs {
    
    NSArray *dialogs = [self.dialogs allValues];
    
    return dialogs;
}

#pragma mark - Dialogs toos
//
//- (NSArray *)allOccupantIDsFromDialogsHistory {
//    
////    NSArray *allDialogs = self.dialogHistory;
//    NSMutableSet *ids = [NSMutableSet set];
//    
//    for (QBChatDialog *dialog in allDialogs) {
//        [ids addObjectsFromArray:dialog.occupantIDs];
//    }
//    
//    return ids.allObjects;
//}

//- (NSArray *)occupantsWithoutMe:(NSArray *)occupants
//{
//    NSMutableSet *occupantsSet = [NSMutableSet setWithArray:occupants];
//    
////    QBUUser *currentUser = [self.serviceDataDelegate serviceDataCurrentProfile];
//    for (QBUUser *opponent in occupants) {
//        if (![opponent isEqual:currentUser]) {
//            [occupantsSet addObject:opponent];
//        }
//    }
//    
//    return [occupantsSet copy];
//}

- (NSArray *)unreadDialogs {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"unreadMessagesCount > 0"];
    NSArray *result = [self.dialogs.allValues filteredArrayUsingPredicate:predicate];

    return result;
}

- (void)setMessages:(NSArray *)messages
       withDialogID:(NSString *)dialogID {
    
    self.messages[dialogID] = messages.mutableCopy;
//    [self.multicastDelegate chatServiceDidMessagesHistoryUpdated];
}

- (void)addMessageToHistory:(QBChatMessage *)message
               withDialogID:(NSString *)dialogID {
    
    NSAssert(message.cParamDialogID == dialogID, @"Check this case");
    NSMutableArray *history = self.messages[dialogID];
    [history addObject:message];
    
//    [self.multicastDelegate chatServiceDidMessagesHistoryUpdated];
}

- (NSArray *)messageHistoryWithDialogID:(NSString *)dialogID {
    
    NSArray *messages = self.messages[dialogID];
    return messages;
}

- (NSArray *)messagesHistoryWithDialog:(QBChatDialog *)chatDialog {
    
    return [self messageHistoryWithDialogID:chatDialog.ID];
}

- (NSArray *)dialogsSortByLastMessageDateWithAscending:(BOOL)ascending {
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"lastMessageDate"
                                                           ascending:ascending];
    
    NSArray *sortedDialogs =  [self.dialogs.allValues sortedArrayUsingDescriptors:@[sort]];

    return sortedDialogs;
};

- (NSUInteger)oponentIDForPrivateChatdDialog:(QBChatDialog *)dialog {
    
    if (dialog.type == QBChatDialogTypePrivate) {
        
    }
    return 0;
}

@end
