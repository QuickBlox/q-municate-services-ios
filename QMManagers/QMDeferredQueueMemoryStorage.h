//
//  QMDeferredQueueMemoryStorage.h
//  QMServices
//
//  Created by Vitaliy Gurkovsky on 8/16/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMDeferredQueueMemoryStorage : NSObject <QMMemoryStorageProtocol>

- (void)addMessage:(QBChatMessage *)message;

- (void)removeMessage:(QBChatMessage *)message;

- (void)addMessages:(NSArray QB_GENERIC(QBChatMessage *) *)messages;
- (void)removeMessages:(NSArray QB_GENERIC(QBChatMessage *) *)messages;

@end
