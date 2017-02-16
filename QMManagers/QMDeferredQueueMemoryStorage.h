//
//  QMDeferredQueueMemoryStorage.h
//  QMServices
//
//  Created by Vitaliy Gurkovsky on 8/16/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMMemoryStorageProtocol.h"
#import <Quickblox/Quickblox.h>

NS_ASSUME_NONNULL_BEGIN

@interface QMDeferredQueueMemoryStorage : NSObject <QMMemoryStorageProtocol>

- (void)addMessage:(QBChatMessage *)message;

- (void)removeMessage:(QBChatMessage *)message;

- (BOOL)containsMessage:(QBChatMessage *)message;

- (NSArray<QBChatMessage *> *)messages;
- (NSArray<QBChatMessage *> *)messagesSortedWithDescriptors:(NSArray <NSSortDescriptor *> *)descriptors;

@end

NS_ASSUME_NONNULL_END
