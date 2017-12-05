#import "CDAttachment.h"
#import "QMSLog.h"

@implementation CDAttachment

- (QBChatAttachment *)toQBChatAttachment {
    
    QBChatAttachment *attachment = [[QBChatAttachment alloc] init];
    
    attachment.name = self.name;
    attachment.ID = self.id;
    attachment.url = self.url;
    attachment.type = self.mimeType;

    NSDictionary *customParameters = [self objectsWithBinaryData:self.customParameters];
    [customParameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        attachment[key] = obj;
    }];
    return attachment;
}

- (void)updateWithQBChatAttachment:(QBChatAttachment *)attachment {
    
    self.name = attachment.name;
    self.id = attachment.ID;
    self.url = attachment.url;
    self.mimeType = attachment.type;

    self.customParameters = [self binaryDataWithObject:attachment.customParameters];
    
    if (!self.changedValues.count) {
        [self.managedObjectContext refreshObject:self mergeChanges:NO];
    }
    else if (!self.isInserted){
         QMSLog(@"Cache > %@ > %@: %@", self.class, self.id ,self.changedValues);
    }
}

- (NSData *)binaryDataWithObject:(id)object {
    
    NSData *binaryData = [NSKeyedArchiver archivedDataWithRootObject:object];
    return binaryData;
}

- (id)objectsWithBinaryData:(NSData *)data {
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

@end
