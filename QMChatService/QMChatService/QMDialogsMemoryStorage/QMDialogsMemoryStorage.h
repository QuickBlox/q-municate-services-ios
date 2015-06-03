//
//  QMDialogsMemoryStorage.h
//  Q-municate
//
//  Created by Andrey on 03.11.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quickblox/Quickblox.h>
#import "QMMemoryStorageProtocol.h"

@interface QMDialogsMemoryStorage : NSObject <QMMemoryStorageProtocol>

- (void)addChatDialog:(QBChatDialog *)chatDialog andJoin:(BOOL)join;
- (void)addChatDialogs:(NSArray *)dialogs andJoin:(BOOL)join;

- (void)deleteChatDialogWithID:(NSString *)chatDialogID;

- (QBChatDialog *)chatDialogWithID:(NSString *)dialogID;
- (QBChatDialog *)chatDialogWithRoomName:(NSString *)roomName;
- (QBChatDialog *)privateChatDialogWithOpponentID:(NSUInteger)opponentID;

- (NSArray *)unreadDialogs;
- (NSArray *)unsortedDialogs;
- (NSArray *)dialogsSortByLastMessageDateWithAscending:(BOOL)ascending;

@end
