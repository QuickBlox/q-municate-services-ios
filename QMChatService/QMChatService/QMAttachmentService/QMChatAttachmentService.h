//
//  QMChatAttachmentService.h
//  QMServices
//
//  Created by Injoit on 7/1/15.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMChatTypes.h"

#import "QMAttachmentStoreService.h"
#import "QMAttachmentAssetService.h"
#import "QMAttachmentContentService.h"
#import "QMCancellableService.h"

/**
 The current state of the attachment.
 */
typedef NS_ENUM(NSUInteger, QMChatAttachmentState) {
    /** Default attachment state. Attachment has no active processes */
    QMChatAttachmentStateNotLoaded = 0,
    /** The attachment has started the download process. */
    QMChatAttachmentStateDownloading,
    /** The attachment has started the upload process. */
    QMChatAttachmentStateUploading,
    /** The attachment has started the asset-loading process. */
    QMChatAttachmentStatePreparing,
    /** The attachment process has been completed successfully. */
    QMChatAttachmentStateLoaded,
    /** The attachment process failed because of an error. */
    QMChatAttachmentStateError
};

@class QMChatService;
@protocol QMChatAttachmentServiceDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface QMAttachmentOperation : NSBlockOperation

@property (copy, nonatomic) NSString *identifier;
@property QBChatAttachment *attachment;
@property NSError *error;
@property NSOperation *storeOperation;
@property NSOperation *mediaInfoOperation;
@property NSOperation *sendOperation;
@property NSOperation *uploadOperation;

@property (copy, nonatomic) dispatch_block_t cancelBlock;

@end

/**
 *  Chat attachment service
 */
@interface QMChatAttachmentService : NSObject

@property (nonatomic, strong, readonly) QMAttachmentStoreService *storeService;
@property (nonatomic, strong, readonly) QMAttachmentContentService *contentService;
@property (nonatomic, strong, readonly) QMAttachmentAssetService *assetService;


- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

/**
 Initializes an `QMChatAttachmentService` object with the specified store, content and asset service.
 
 @param storeService The `QMAttachmentStoreService` instance.
 @param contentService The `QMAttachmentContentService` instance.
 @param assetService The `QMAttachmentAssetService` instance.
 
 @return The newly-initialized QMChatAttachmentService
 */
- (instancetype)initWithStoreService:(QMAttachmentStoreService *)storeService
                      contentService:(QMAttachmentContentService *)contentService
                        assetService:(QMAttachmentAssetService *)assetService;

- (QMChatAttachmentState)attachmentStateForMessage:(QBChatMessage *)message;
- (void)attachmentWithID:(NSString *)attachmentID
                 message:(QBChatMessage *)message
           progressBlock:(QMAttachmentProgressBlock)progressBlock
              completion:(void(^)(QMAttachmentOperation *op))completionBlock;

- (void)imageForAttachment:(QBChatAttachment *)attachment
                   message:(QBChatMessage *)message
                completion:(void(^)(UIImage * _Nullable image,
                                    NSError * _Nullable error))completion;

- (BOOL)attachmentIsReadyToPlay:(QBChatAttachment *)attachment
                        message:(QBChatMessage *)message;

- (void)cancelOperationsWithMessageID:(NSString *)messageID;

- (void)removeAllMediaFiles;

- (void)removeMediaFilesForDialogWithID:(NSString *)dialogID;

- (void)removeMediaFilesForMessageWithID:(NSString *)messageID
                                dialogID:(NSString *)dialogID;


- (void)removeMediaFilesForMessagesWithID:(NSArray<NSString *> *)messagesIDs
                                 dialogID:(NSString *)dialogID;

- (void)prepareAttachment:(QBChatAttachment *)attachment
                messageID:(NSString *)messageID
               completion:(QMMediaInfoServiceCompletionBlock)completion;

/**
 *  Add delegate (Multicast)
 *
 *  @param delegate Instance confirmed QMChatAttachmentServiceDelegate protocol
 */
- (void)addDelegate:(id <QMChatAttachmentServiceDelegate>)delegate;

/**
 *  Remove delegate from observed list
 *
 *  @param delegate Instance confirmed QMChatAttachmentServiceDelegate protocol
 */
- (void)removeDelegate:(id <QMChatAttachmentServiceDelegate>)delegate;

/**
 *  Chat attachment service delegate
 *
 *  @warning *Deprecated in QMServices 0.4.7:* Use 'addDelegate:' instead.
 */
@property (nonatomic, weak, nullable) id<QMChatAttachmentServiceDelegate> delegate
DEPRECATED_MSG_ATTRIBUTE("Deprecated in 0.4.7. Use 'addDelegate:' instead.");

/**
 *  Upload and send attachment message to dialog.
 *
 *  @param message      QBChatMessage instance
 *  @param dialog       QBChatDialog instance
 *  @param chatService  QMChatService instance
 *  @param image        Attachment image
 *  @param completion   Send message result
 *
 *  @warning *Deprecated in QMServices 0.4.7:* Use 'uploadAndSendAttachmentMessage:toDialog:withChatService:attachment:completion:' instead.
 */
- (void)uploadAndSendAttachmentMessage:(QBChatMessage *)message
                              toDialog:(QBChatDialog *)dialog
                       withChatService:(QMChatService *)chatService
                     withAttachedImage:(UIImage *)image
                            completion:(nullable QBChatCompletionBlock)completion DEPRECATED_MSG_ATTRIBUTE("Deprecated in 0.4.7. Use 'uploadAndSendAttachmentMessage:toDialog:withChatService:attachment:completion:' instead.");

/**
 *  Get image by attachment message.
 *
 *  @param attachmentMessage message with attachment
 *  @param completion        fetched image or error if failed
 */
- (void)imageForAttachmentMessage:(QBChatMessage *)attachmentMessage
                       completion:(nullable void(^)(NSError * _Nullable error, UIImage * _Nullable image))completion DEPRECATED_MSG_ATTRIBUTE("Deprecated in 0.4.7. Use 'imageForAttachment:message:completion:' instead.");

/**
 *  Get image local image by attachment message.
 *
 *  @param attachmentMessage      message with attachment
 *  @param completion             local image or nil if no image
 */
- (void)localImageForAttachmentMessage:(QBChatMessage *)attachmentMessage
                            completion:(nullable void(^)(NSError * _Nullable error, UIImage * _Nullable image))completion DEPRECATED_MSG_ATTRIBUTE("Deprecated in 0.4.7. Use 'imageForAttachment:message:completion:' instead.");

//MARK: - Media

/**
 *  Upload and send attachment message to dialog.
 *
 *  @param message      QBChatMessage instance
 *  @param dialog       QBChatDialog instance
 *  @param chatService  QMChatService instance
 *  @param attachment   QBChatAttachment instance
 *  @param completion   Send message result
 */

- (void)uploadAndSendAttachmentMessage:(QBChatMessage *)message
                              toDialog:(QBChatDialog *)dialog
                       withChatService:(QMChatService *)chatService
                            attachment:(QBChatAttachment *)attachment
                            completion:(nullable QBChatCompletionBlock)completion;

@end



@protocol QMChatAttachmentServiceDelegate <NSObject>

/**
 *  Is called when attachment service did change current state of the attachment.
 *  Please see QMMessageAttachmentState for additional info.
 *
 *  @param chatAttachmentService The 'QMChatAttachmentService' instance.
 *  @param attachmentState The current state of the attachment.
 *  @param attachment The 'QBChatAttachment' instance.
 *  @param messageID The message ID that contains attachment.
 */
- (void)chatAttachmentService:(QMChatAttachmentService *)chatAttachmentService
     didChangeAttachmentState:(QMChatAttachmentState)attachmentState
                forAttachment:(QBChatAttachment *)attachment
                withMessageID:(NSString *)messageID;

/**
 *  Is called when chat attachment service did change loading progress for some attachment.
 *  Used for display loading progress.
 *
 *  @param chatAttachmentService instance QMChatAttachmentService
 *  @param progress changed value of progress min 0.0, max 1.0
 *  @param attachment loaded QBChatAttachment
 *
 *  @warning *Deprecated in QMServices 0.4.7:* Use 'uploadAndSendAttachmentMessage:toDialog:withChatService:attachment:completion:' instead.
 */

- (void)chatAttachmentService:(QMChatAttachmentService *)chatAttachmentService
     didChangeLoadingProgress:(CGFloat)progress
            forChatAttachment:(QBChatAttachment *)attachment

DEPRECATED_MSG_ATTRIBUTE("Deprecated in 0.4.7. Use 'chatAttachmentService:didChangeUploadingProgress:forMessage:attachment:' instead.");;

/**
 *  Is called when chat attachment service did change Uploading progress for attachment in message.
 *  Used for display loading progress.
 *
 *  @param chatAttachmentService QMChatAttachmentService instance.
 *  @param progress              Changed value of progress. Min 0.0, max 1.0.
 *  @param message               Message that contains attachment.
 */
- (void)chatAttachmentService:(QMChatAttachmentService *)chatAttachmentService
   didChangeUploadingProgress:(CGFloat)progress
                   forMessage:(QBChatMessage *)message;


- (void)chatAttachmentService:(QMChatAttachmentService *)chatAttachmentService
     didChangeLoadingProgress:(CGFloat)progress
                   forMessage:(QBChatMessage *)message
                   attachment:(QBChatAttachment *)attachment;


@end

NS_ASSUME_NONNULL_END
