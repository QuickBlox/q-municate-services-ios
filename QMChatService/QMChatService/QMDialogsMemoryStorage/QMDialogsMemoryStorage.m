//
//  QMDialogsMemoryStorage.m
//  Q-municate
//
//  Created by Andrey on 03.11.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMDialogsMemoryStorage.h"
#import "QBChatMessage+QMCustomParameters.h"

@interface QMDialogsMemoryStorage()

@property (strong, nonatomic) NSMutableDictionary *dialogs;
@property (strong, nonatomic) NSMutableArray *blocks;

@end

@implementation QMDialogsMemoryStorage

- (void)dealloc {
    
    [self.dialogs removeAllObjects];
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        self.dialogs = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Add / Join / Remove

- (void)addChatDialog:(QBChatDialog *)chatDialog andJoin:(BOOL)join {
    
    self.dialogs[chatDialog.ID] = chatDialog;
    
    if (join) {
        
        if (!chatDialog.chatRoom.isJoined) {
            [chatDialog.chatRoom joinRoomWithHistoryAttribute:@{@"maxstanzas": @"0"}];
        }
    }
}

- (void)addChatDialogs:(NSArray *)dialogs andJoin:(BOOL)join {
    
    for (QBChatDialog *chatDialog in dialogs) {
        
        [self addChatDialog:chatDialog andJoin:join];
    }
}

- (void)deleteChatDialogWithID:(NSString *)chatDialogID
{
    [self.dialogs removeObjectForKey:chatDialogID];
}

- (QBChatDialog *)chatDialogWithID:(NSString *)dialogID {
    
    return self.dialogs[dialogID];
}

- (QBChatDialog *)privateChatDialogWithOpponentID:(NSUInteger)opponentID {
    
    NSArray *allDialogs = [self unreadDialogs];
    
    NSPredicate *predicate =
    [NSPredicate predicateWithFormat:@"SELF.type == %d AND SUBQUERY(SELF.occupantIDs, $userID, $userID == %@).@count > 0", QBChatDialogTypePrivate, @(opponentID)];
    
    NSArray *result = [allDialogs filteredArrayUsingPredicate:predicate];
    QBChatDialog *dialog = result.firstObject;
    
    return dialog;
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

- (NSArray *)unreadDialogs {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"unreadMessagesCount > 0"];
    NSArray *result = [self.dialogs.allValues filteredArrayUsingPredicate:predicate];

    return result;
}

- (NSArray *)dialogsSortByLastMessageDateWithAscending:(BOOL)ascending {
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"lastMessageDate" ascending:ascending];
    
    NSArray *sortedDialogs =  [self.dialogs.allValues sortedArrayUsingDescriptors:@[sort]];

    return sortedDialogs;
};

#pragma mark - QMMemoryStorageProtocol

- (void)free {
    
    [self.dialogs removeAllObjects];
}

@end
