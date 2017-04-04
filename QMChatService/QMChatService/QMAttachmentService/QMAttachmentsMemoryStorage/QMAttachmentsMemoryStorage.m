//
//  QMAttachmentsMemoryStorage.m
//  Pods
//
//  Created by Vitaliy Gurkovsky on 3/25/17.
//
//

#import "QMAttachmentsMemoryStorage.h"

@interface QMAttachmentsMemoryStorage()

@property (strong, nonatomic) NSMutableDictionary *datasources;

@end

@implementation QMAttachmentsMemoryStorage

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        self.datasources = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addAttachment:(QBChatAttachment *)attachment {
    
    NSString *messageID = @"dfdfbdf";
        NSMutableOrderedSet *datasource = [self dataSourceWithMessageID:messageID];
    
    NSUInteger indexOfMessage = [datasource indexOfObject:attachment];
    
    if (indexOfMessage != NSNotFound) {
        
        [datasource replaceObjectAtIndex:indexOfMessage withObject:attachment];
        
    }
    else {
        
        [datasource addObject:attachment];
    }
}


- (QBChatAttachment *)attachmentWithID:(NSString *)atatchmentID messageID:(NSString *)messageID {
    
    NSParameterAssert(atatchmentID != nil);
    NSParameterAssert(messageID != nil);
    
    NSMutableOrderedSet *attachments = [self dataSourceWithMessageID:messageID];
    
    for (QBChatAttachment *attachment in attachments) {
        
        if ([attachment.ID isEqualToString:atatchmentID]) {
            
            return attachment;
        }
    }
    
    return nil;
}

#pragma mark - QMMemeoryStorageProtocol

- (void)free {
    
    [self.datasources removeAllObjects];
}

- (NSMutableOrderedSet *)dataSourceWithMessageID:(NSString *)messageID {
    
    NSMutableOrderedSet *attachments = self.datasources[messageID];
    
    if (!attachments) {
        attachments = [NSMutableOrderedSet orderedSet];
        self.datasources[messageID] = attachments;
    }
    
    return attachments;
}

@end
