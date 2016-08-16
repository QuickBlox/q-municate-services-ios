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

@property (strong, nonatomic) QBMulticastDelegate <QMDeferredQueueManagerDelegate> *multicastDelegate;

- (void)addMessage:(QBChatMessage *)message;
- (void)updateMessage:(QBChatMessage *)message;
- (void)removeMessage:(QBChatMessage *)message;
- (QMMessageStatus)statusForMessage:(QBChatMessage *)message;

@end


@protocol QMDeferredQueueManagerDelegate <NSObject>

@optional

- (void)deferredQueueManager:(QMDeferredQueueManager*)queueManager performActionWithMessage:(QB_NONNULL QBChatMessage *)message;

@end
