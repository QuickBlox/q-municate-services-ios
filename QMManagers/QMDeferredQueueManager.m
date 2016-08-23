//
//  QMDeferredQueueManager.m
//  QMServices
//
//  Created by Vitaliy Gurkovsky on 8/16/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "QMDeferredQueueManager.h"
#import "QMDeferredQueueMemoryStorage.h"

@interface QMDeferredQueueManager()

@property (strong, nonatomic) QBMulticastDelegate <QMDeferredQueueManagerDelegate> *multicastDelegate;
@property (strong, nonatomic) QMDeferredQueueMemoryStorage * deferredQueueMemoryStorage;
@end

@implementation QMDeferredQueueManager

#pragma mark - 
#pragma mark Life Cycle

- (instancetype)init {
    
    self = [super init];
    
    if (self) {
        _deferredQueueMemoryStorage = [[QMDeferredQueueMemoryStorage alloc] init];
        _multicastDelegate = [[QBMulticastDelegate alloc] init];
    }

    return self;
}

- (void)dealloc {
    
}

#pragma mark -
#pragma mark MulticastDelegate

- (void)addDelegate:(QB_NONNULL id <QMDeferredQueueManagerDelegate>)delegate {
    [self.multicastDelegate addDelegate:delegate];
}

- (void)removeDelegate:(QB_NONNULL id <QMDeferredQueueManagerDelegate>)delegate {
    [self.multicastDelegate removeDelegate:delegate];
}

#pragma mark -
#pragma mark Messages

- (void)addOrUpdateMessage:(QBChatMessage *)message {
    
    BOOL messageIsExisted = [self.deferredQueueMemoryStorage containsMessage:message];
    
    [self.deferredQueueMemoryStorage addMessage:message];
    
    if (!messageIsExisted && [self.multicastDelegate respondsToSelector:@selector(deferredQueueManager:didAddMessageLocally:)]) {
        
        [self.multicastDelegate deferredQueueManager:self
                                didAddMessageLocally:message];
    }
}

- (void)removeMessage:(QBChatMessage *)message {
    [self.deferredQueueMemoryStorage removeMessage:message];
}

- (QMMessageStatus)statusForMessage:(QBChatMessage *)message {
    
    if ([self.deferredQueueMemoryStorage containsMessage:message]) {
        return [[QBChat instance] isConnected] ? QMMessageStatusSending : QMMessageStatusNotSent;
    }
    else {
        return QMMessageStatusSent;
    }
}

- (void)perfromDefferedActionForMessage:(QBChatMessage*)message {
    
    BOOL messageIsExisted = [self.deferredQueueMemoryStorage containsMessage:message];
    
    if (messageIsExisted && [self.multicastDelegate respondsToSelector:@selector(deferredQueueManager:performActionWithMessage:)]) {
        [self.multicastDelegate deferredQueueManager:self
                            performActionWithMessage:message];
    }
}

#pragma mark -
#pragma mark Deferred Queue Operations
- (void)performDeferredActions {
    
    for (QBChatMessage * message in self.deferredQueueMemoryStorage.messages) {
        [self perfromDefferedActionForMessage:message];
    }
}

@end
