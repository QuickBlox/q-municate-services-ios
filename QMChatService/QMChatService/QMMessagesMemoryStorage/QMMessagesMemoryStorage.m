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

- (void)addMessage:(QBChatMessage *)message
       forDialogID:(NSString *)dialogID {
    
    NSMutableArray *datasource = [self datasourceWithDialogID:dialogID];

    [datasource addObject:message];
}

#pragma mark - replace

- (void)replaceMessages:(NSArray *)messages
            forDialogID:(NSString *)dialogID {
    
    NSMutableArray *datasource = [self datasourceWithDialogID:dialogID];
    [datasource removeAllObjects];
    [datasource addObjectsFromArray:messages];
}

#pragma mark - Getters

- (NSMutableArray *)datasourceWithDialogID:(NSString *)dialogID {
    
    NSMutableArray *messages = self.datasources[dialogID];
    
    if (!messages) {
        messages = [NSMutableArray array];
    }
    
    return messages;
}

- (NSArray *)messagesWithDialogID:(NSString *)dialogID {
    
    NSMutableArray *messages = self.datasources[dialogID];
    
    return [messages copy];
}

#pragma mark - Clean up

- (void)cleanUp {
    
    [self.datasources removeAllObjects];
}

@end
