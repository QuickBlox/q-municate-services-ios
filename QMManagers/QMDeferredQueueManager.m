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
@property (strong, nonatomic) QMDeferredQueueMemoryStorage *deferredQueueMemoryStorage;
@property (strong, nonatomic) NSMutableSet<NSString *> *performingMessagesIDs;

@end

@implementation QMDeferredQueueManager

//MARK: - Life Cycle

- (instancetype)initWithServiceManager:(id<QMServiceManagerProtocol>)serviceManager {
    self = [super initWithServiceManager:serviceManager];
    if (self) {
        
        _deferredQueueMemoryStorage = [[QMDeferredQueueMemoryStorage alloc] init];
        _multicastDelegate = (id <QMDeferredQueueManagerDelegate>)[[QBMulticastDelegate alloc] init];
        _autoSendTimeInterval = 60 * 10; //10 minutes
        _performingMessagesIDs = [NSMutableSet set];
        _maxDeferredActionsCount = 3;
    }
    
    return self;
}

- (void)free {
    
    [_deferredQueueMemoryStorage free];
    [_performingMessagesIDs removeAllObjects];
}

- (void)dealloc {
    
}

//MARK: - MulticastDelegate

- (void)addDelegate:(id)delegate {
    [self.multicastDelegate addDelegate:delegate];
}

- (void)removeDelegate:(id)delegate {
    [self.multicastDelegate removeDelegate:delegate];
}

//MARK: - Messages

- (NSUInteger)numberOfNotSentMessagesForDialogWithID:(NSString *)dialogID {
    
    NSPredicate *predicate =
    [NSPredicate predicateWithBlock:^BOOL(QBChatMessage *message,
                                          NSDictionary<NSString *,id> * bindings) {
        
        return [message.dialogID isEqualToString:dialogID] &&
        [self statusForMessage:message] == QMMessageStatusNotSent;
    }];
    
    NSArray<QBChatMessage *> *messages =
    [self.deferredQueueMemoryStorage.messages filteredArrayUsingPredicate:predicate];
    
    return messages.count;
}

- (NSArray<QBChatMessage *> *)messagesForDialogWithID:(NSString *)dialogID {
    
    NSPredicate *predicate =
    [NSPredicate predicateWithBlock:^BOOL(QBChatMessage *message,
                                          NSDictionary<NSString *,id> *bindings) {
        
        return [message.dialogID isEqualToString:dialogID];
    }];
    
    NSArray<QBChatMessage *> *messages =
    [self.deferredQueueMemoryStorage.messages filteredArrayUsingPredicate:predicate];
    
    return messages;
}

- (void)addOrUpdateMessage:(QBChatMessage *)message {
    
    BOOL messageIsExisted =
    [self.deferredQueueMemoryStorage containsMessage:message];
    
    [self.deferredQueueMemoryStorage addMessage:message];
    NSLog(@"_DEFFERED QUEUE ADD OR UPDATE_%@ has message:%@", message.ID, messageIsExisted ? @"YES" : @"NO");
    if (!messageIsExisted) {
        
        if ([self.multicastDelegate respondsToSelector:@selector(deferredQueueManager:didAddMessageLocally:)]) {
            [self.multicastDelegate deferredQueueManager:self
                                    didAddMessageLocally:message];
        }
    }
    else {
        if ([self.multicastDelegate respondsToSelector:@selector(deferredQueueManager:didUpdateMessageLocally:)]) {
            [self.multicastDelegate deferredQueueManager:self
                                    didUpdateMessageLocally:message];
        }
    }
}

- (void)removeMessage:(QBChatMessage *)message {
    
    [self.deferredQueueMemoryStorage removeMessage:message];
    [self.performingMessagesIDs removeObject:message.ID];
}

- (QMMessageStatus)statusForMessage:(QBChatMessage *)message {
    
    if ([self.deferredQueueMemoryStorage containsMessage:message]) {
        
        // NSLog(@"_DEFFERED QUEUE CONTAINS_%@", message.ID);
        
        return ([[QBChat instance] isConnected] &&
                [self isAutoSendAvailableForMessage:message]) ? QMMessageStatusSending : QMMessageStatusNotSent;
    }
    else {
        return QMMessageStatusSent;
    }
}

//MARK: - Deferred Queue Operations

- (BFTask *)perfromDefferedActionForMessage:(QBChatMessage *)message {
    
    if ([self.performingMessagesIDs containsObject:message.ID]) {
         NSLog(@"_DEFFERED QUEUE perfromDefferedAction CONTAINS_%@", message.ID);
        return nil;
    }
    
    [self.performingMessagesIDs addObject:message.ID];
    
    BFTaskCompletionSource *completionSource = [BFTaskCompletionSource taskCompletionSource];
    
    [self perfromDefferedActionForMessage:message
                           withCompletion:^(NSError * _Nullable error) {
        NSLog(@"_DEFFERED QUEUE perfromDefferedAction COMPLETION %@", message.ID);
        [self.performingMessagesIDs removeObject:message.ID];
        
        if (error != nil) {
            [completionSource setError:error];
        }
        else {
            [completionSource setResult:nil];
        }
    }];
    
    return completionSource.task;
}

- (void)performDeferredActionsForDialogWithID:(NSString *)dialogID {
    
    NSArray<QBChatMessage *> *messages =
    [self messagesForDialogWithID:dialogID];
    
    for (QBChatMessage *message in messages) {
        
        BFTask *task = [BFTask taskWithResult:nil];
        if ([self isAutoSendAvailableForMessage:message]) {
            
            task = [task continueWithBlock:^id(BFTask *task) {
                
                return [self perfromDefferedActionForMessage:message];
            }];
        }
        else {
            continue;
        }
    }
}

- (void)performDeferredActions {
    
    
    for (QBChatMessage *message in self.deferredQueueMemoryStorage.messages) {
        
        BFTask *task = [BFTask taskWithResult:nil];
        
        task = [task continueWithBlock:^id(BFTask *task) {
            return [self perfromDefferedActionForMessage:message];
        }];
    }
}

- (void)perfromDefferedActionForMessage:(QBChatMessage *)message withCompletion:(QBChatCompletionBlock)completion {
    
    BOOL messageIsExisted = [self.deferredQueueMemoryStorage containsMessage:message];
    NSParameterAssert(messageIsExisted);
    
    if (messageIsExisted
        && [self.multicastDelegate respondsToSelector:@selector(deferredQueueManager:
                                                                performActionWithMessage:
                                                                withCompletion:)]) {
        
        [self.multicastDelegate deferredQueueManager:self
                            performActionWithMessage:message
                                      withCompletion:completion];
    }
}

//MARK: - Helpers

- (BOOL)isAutoSendAvailableForMessage:(QBChatMessage *)message {
    
    NSTimeInterval secondsBetween = [[NSDate date] timeIntervalSinceDate:message.dateSent];

    BOOL isAvailable = secondsBetween <= self.autoSendTimeInterval;
    NSLog(@"_DEFFERED QUEUE isAutoSendAvailableForMessage %@ %@", message.ID, isAvailable ? @"YES" : @"NO");
    return isAvailable;
}

- (BOOL)shouldSendMessagesInDialogWithID:(NSString *)dialogID {
    
    if ([[QBChat instance] isConnected] || self.maxDeferredActionsCount == 0) {
        return YES;
    }
    
    NSUInteger messagesCount = [self numberOfNotSentMessagesForDialogWithID:dialogID];
    return self.maxDeferredActionsCount > messagesCount;
}

//MARK: -
//MARK: QMMemoryTemporaryQueueDelegate

- (NSArray *)localMessagesForDialogWithID:(NSString *)dialogID {
    
    return [self messagesForDialogWithID:dialogID];
}

@end
