//
//  QMChatAttachmentService.h
//  QMServices
//
//  Created by Injoit on 7/1/15.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMChatTypes.h"

#import "QMMediaStoreService.h"
#import "QMMediaInfoService.h"
#import "QMMediaWebService.h"
#import "QMCancellableService.h"



//typedef NS_ENUM(NSUInteger, QMAttachmentStatus) {
//    QMAttachmentStatusNotLoaded = 0,
//    QMAttachmentStatusLoading,
//    QMAttachmentStatusLoaded,
//    QMAttachmentStatusPreparing,
//    QMAttachmentStatusPrepared,
//    QMAttachmentStatusError
//};

@class QMChatService;
@protocol QMChatAttachmentServiceDelegate;

NS_ASSUME_NONNULL_BEGIN

struct QMAttachmentStatusStruct {
    __unsafe_unretained NSString *notLoaded;
    __unsafe_unretained NSString *loading;
    __unsafe_unretained NSString *loaded;
    __unsafe_unretained NSString *preparing;
    __unsafe_unretained NSString *prepared;
    __unsafe_unretained NSString *error;
};

extern const struct QMAttachmentStatusStruct QMAttachmentStatus;

    

/**
 *  Chat attachment service
 */
@interface QMChatAttachmentService : NSObject

@property (nonatomic, strong, readonly) QMMediaStoreService *storeService;
@property (nonatomic, strong, readonly) QMMediaWebService *webService;
@property (nonatomic, strong, readonly) QMMediaInfoService *infoService;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;


- (NSString *)statusForMessage:(QBChatMessage *)message;

- (instancetype)initWithStoreService:(QMMediaStoreService *)storeService
                          webService:(QMMediaWebService *)webService
                         infoService:(QMMediaInfoService *)infoService;

- (QBChatAttachment *)placeholderAttachment:(NSString *)messageID;

- (void)imageForAttachment:(QBChatAttachment *)attachment
                   message:(QBChatMessage *)message
                completion:(void(^)(UIImage *image,
                                    QMMediaError *error))completion;

- (void)attachmentWithID:(NSString *)attachmentID
                 message:(QBChatMessage *)message
              completion:(void(^)(QBChatAttachment * _Nullable attachment,
                                  NSError * _Nullable error,
                                  QMMessageAttachmentStatus status))completion;

- (BOOL)attachmentIsReadyToPlay:(QBChatAttachment *)attachment
                        message:(QBChatMessage *)message;

- (void)cancelOperationsForAttachment:(QBChatAttachment *)attachment
                            messageID:(NSString *)messageID;

- (void)removeAllMediaFiles;

- (void)removeMediaFilesForDialogWithID:(NSString *)dialogID;

- (void)removeMediaFilesForMessageWithID:(NSString *)messageID
                                dialogID:(NSString *)dialogID;


- (void)removeMediaFilesForMessagesWithID:(NSArray<NSString *> *)messagesIDs
                                 dialogID:(NSString *)dialogID;
- (void)prepareAttachment:(QBChatAttachment *)attachment messageID:(NSString *)messageID
               completion:(QMMediaInfoServiceCompletionBlock)completion;
/**
 *  Add delegate (Multicast)
 *
 *  @param delegate Instance confirmed QMChatServiceDelegate protocol
 */
- (void)addDelegate:(id <QMChatAttachmentServiceDelegate>)delegate;

/**
 *  Remove delegate from observed list
 *
 *  @param delegate Instance confirmed QMChatServiceDelegate protocol
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

- (void)chatAttachmentService:(QMChatAttachmentService *)chatAttachmentService
          didUpdateAttachment:(QBChatAttachment *)attachment
                  forMesssage:(QBChatMessage *)message;

/**
 *  Is called when attachment service did change attachment status for some message.
 *  Please see QMMessageAttachmentStatus for additional info.
 *
 *  @param chatAttachmentService instance QMChatAttachmentService
 *  @param status new status
 *  @param message new status owner QBChatMessage
 */
- (void)chatAttachmentService:(QMChatAttachmentService *)chatAttachmentService
    didChangeAttachmentStatus:(NSString *)status
                   forMessageID:(NSString *)messageID;

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
 *  @param chatAttachmentService QMChatAttachmentService instance
 *  @param progress              changed value of progress min 0.0, max 1.0
 *  @param messageID             ID of message that contains attachment
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
