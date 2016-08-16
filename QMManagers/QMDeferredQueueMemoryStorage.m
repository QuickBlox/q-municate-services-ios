//
//  QMDeferredQueueMemoryStorage.m
//  QMServices
//
//  Created by Vitaliy Gurkovsky on 8/16/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "QMDeferredQueueMemoryStorage.h"

@interface QMDeferredQueueMemoryStorage()

@property (strong, nonatomic) NSMutableDictionary *messages;
@property (strong, nonatomic) NSMutableDictionary *dialogs;
@property (strong, nonatomic) NSMutableDictionary *contactRequests;

@end

@implementation QMDeferredQueueMemoryStorage

- (void)dealloc {
    [self.messages removeAllObjects];
    [self.dialogs removeAllObjects];
    [self.contactRequests removeAllObjects];
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        self.dialogs = [NSMutableDictionary dictionary];
        self.messages = [NSMutableDictionary dictionary];
        self.contactRequests = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addMessage:(QBChatMessage *)message {
    QBChatMessage *message = self.messages[message.ID];
    if (message != nil) {
        
    }
    self.messages[message.ID] = message;
}

- (void)removeMessage:(QBChatMessage *)message {
    [self.messages removeObjectForKey:message.ID];
}

#pragma mark - QMMemoryStorageProtocol

- (void)free {

    [self.messages removeAllObjects];
    [self.dialogs removeAllObjects];
    [self.contactRequests removeAllObjects];
}

@end
