//
//  QMDeferredQueueManager.h
//  QMServices
//
//  Created by Vitaliy Gurkovsky on 8/16/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol QMDeferredQueueManagerDelegate;

typedef NS_ENUM(NSUInteger, QMMessageStatus) {
    QMMessageStatusSent = 0,
    QMMessageStatusSending,
    QMMessageStatusNotSent
};

@interface QMDeferredQueueManager : NSObject

- (void)addDelegate:(QB_NONNULL id <QMDeferredQueueManagerDelegate>)delegate;
- (void)removeDelegate:(QB_NONNULL id <QMDeferredQueueManagerDelegate>)delegate;


- (void)addOrUpdateMessage:(QBChatMessage *)message;
- (void)removeMessage:(QBChatMessage *)message;

- (QMMessageStatus)statusForMessage:(QBChatMessage *)message;
- (void)performDeferredActions;

@end


@protocol QMDeferredQueueManagerDelegate <NSObject>

@optional

- (void)deferredQueueManager:(QMDeferredQueueManager*)queueManager performActionWithMessage:(QB_NONNULL QBChatMessage *)message;
- (void)deferredQueueManager:(QMDeferredQueueManager*)queueManager didAddMessageLocally:(QBChatMessage*)addedMessage;

@end
