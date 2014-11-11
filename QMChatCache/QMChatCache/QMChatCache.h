//
//  QMChatCache.h
//  QMChatCache
//
//  Created by Andrey on 06.11.14.
//
//

#import <Foundation/Foundation.h>
#import "QMDBStorage.h"

@interface QMChatCache : QMDBStorage

+ (QMChatCache *)instance;

+ (void)setupDBWithStoreNamed:(NSString *)storeName;

- (void)cachedQBChatDialogs:(void(^)(NSArray *dialogs))qbDialogs;
- (void)cacheQBDialogs:(NSArray *)dialogs finish:(void(^)(void))finish;

- (void)cacheQBChatMessages:(NSArray *)messages withDialogId:(NSString *)dialogId finish:(void(^)(void))finish;
- (void)cachedQBChatMessagesWithDialogId:(NSString *)dialogId qbMessages:(void(^)(NSArray *dialogs))qbMessages;
- (void)allCachedQBChatMessages:(void(^)(NSArray *dialogs))qbMessages;

@end
