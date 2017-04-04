//
//  QMAttachmentsMemoryStorage.h
//  Pods
//
//  Created by Vitaliy Gurkovsky on 3/25/17.
//
//

#import <Foundation/Foundation.h>
#import <Quickblox/Quickblox.h>
#import "QMMemoryStorageProtocol.h"

@interface QMAttachmentsMemoryStorage : NSObject <QMMemoryStorageProtocol>

- (void)addAttachment:(QBChatAttachment *)attachment;
- (void)updateAttachment:(QBChatAttachment *)attachment;

- (QBChatAttachment *)attachmentForAttachmentID:(NSString *)attachmentID;

@end
