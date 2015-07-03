//
//  QMChatAttachmentService.h
//  QMChatService
//
//  Created by Injoit on 7/1/15.
//
//

#import <Foundation/Foundation.h>
#import "QMChatTypes.h"

@class QMChatService;
@class QMChatAttachmentService;

@protocol QMChatAttachmentServiceDelegate <NSObject>

- (void)chatAttachmentService:(QMChatAttachmentService *)chatAttachmentService didChangeAttachmentStatus:(QMMessageAttachmentStatus)status forMessage:(QBChatMessage *)message;

- (void)chatAttachmentService:(QMChatAttachmentService *)chatAttachmentService didChangeLoadingProgress:(CGFloat)progress forChatAttachment:(QBChatAttachment *)attachment;

@end

@interface QMChatAttachmentService : NSObject

@property (nonatomic, weak) id<QMChatAttachmentServiceDelegate> delegate;

- (void)sendMessage:(QBChatMessage *)message toDialog:(QBChatDialog *)dialog withChatService:(QMChatService *)chatService withAttachedImage:(UIImage *)image completion:(void(^)(NSError *error))completion;

- (void)getImageForChatAttachment:(QBChatAttachment *)attachment completion:(void (^)(NSError *error, UIImage *image))completion;


@end
