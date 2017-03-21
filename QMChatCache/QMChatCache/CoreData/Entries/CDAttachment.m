#import "CDAttachment.h"

@implementation CDAttachment

- (QBChatAttachment *)toQBChatAttachment {
    
    QBChatAttachment *attachment = [[QBChatAttachment alloc] init];
    
    attachment.name = self.name;
    attachment.ID = self.id;
    attachment.url = self.url;
    attachment.type = self.mimeType;
    attachment.data = self.data;
    attachment.width = self.width.unsignedIntegerValue;
    attachment.height = self.height.unsignedIntegerValue;
    attachment.size = self.size.unsignedIntegerValue;
    attachment.duration = self.duration.doubleValue;
    
    return attachment;
}

- (void)updateWithQBChatAttachment:(QBChatAttachment *)attachment {
    
    self.name = attachment.name;
    self.id = attachment.ID;
    self.url = attachment.url;
    self.mimeType = attachment.type;
    self.data = attachment.data;
    self.width = @(attachment.width);
    self.height = @(attachment.height);
    self.size = @(attachment.size);
    self.duration = @(attachment.duration);
}

@end
