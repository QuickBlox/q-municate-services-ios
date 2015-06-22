//
//  QMMessagesMemoryStorage.m
//  QMChatService
//
//  Created by Andrey on 28.11.14.
//
//

#import "QMMessagesMemoryStorage.h"

@interface QMMessagesMemoryStorage()

@property (strong, nonatomic) NSMutableDictionary *datasources;

@end

@implementation QMMessagesMemoryStorage

- (instancetype)init {
    
    self = [super init];
    if (self) {
        self.datasources = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Setters

- (void)addMessage:(QBChatMessage *)message forDialogID:(NSString *)dialogID {
    
    NSMutableArray *datasource = [self dataSourceWithDialogID:dialogID];

    [datasource addObject:message];
}

#pragma mark - replace

- (void)replaceMessages:(NSArray *)messages forDialogID:(NSString *)dialogID {
    
    NSMutableArray *datasource = [self dataSourceWithDialogID:dialogID];
    [datasource removeAllObjects];
    [datasource addObjectsFromArray:messages];
}

#pragma mark - Getters

- (NSMutableArray *)dataSourceWithDialogID:(NSString *)dialogID {
    
    NSMutableArray *messages = self.datasources[dialogID];
    
    if (!messages) {
        messages = [NSMutableArray array];
        self.datasources[dialogID] = messages;
    }
    
    return messages;
}

- (NSArray *)messagesWithDialogID:(NSString *)dialogID {
    
    NSMutableArray *messages = self.datasources[dialogID];
    
    return [messages copy];
}

- (void)deleteMessagesWithDialogID:(NSString *)dialogID {
	
	[self.datasources removeObjectForKey:dialogID];
}

#pragma mark - QMMemeoryStorageProtocol

- (void)free {
    
    [self.datasources removeAllObjects];
}

@end
