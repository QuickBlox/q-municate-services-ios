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

- (void)addMessages:(NSArray *)messages forDialogID:(NSString *)dialogID {
    
    NSMutableArray *datasource = [self dataSourceWithDialogID:dialogID];
    
    [datasource addObjectsFromArray:messages];
    
    [self sortMessagesForDialogID:dialogID];
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

- (BOOL)isEmptyForDialogID:(NSString *)dialogID {
    
    NSArray *messages = self.datasources[dialogID];
    
    return !messages || [messages count] == 0;
}

- (QBChatMessage *)oldestMessageForDialogID:(NSString *)dialogID {
    
    NSArray *messages = [self messagesWithDialogID:dialogID];
    
    return [messages firstObject];
}

- (void)sortMessagesForDialogID:(NSString *)dialogID {
    
    NSMutableArray *datasource = [self dataSourceWithDialogID:dialogID];
    
    [datasource sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"dateSent" ascending:YES]]];
}

#pragma mark - QMMemeoryStorageProtocol

- (void)free {
    
    [self.datasources removeAllObjects];
}

@end
