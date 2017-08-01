//
//  QMMediaBlocks.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/8/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import "QMChatTypes.h"

@class QBCBlob;


NS_ASSUME_NONNULL_BEGIN


typedef void (^QMAttachmentDownloadCancellBlock)(QBChatAttachment *attachment);
typedef void (^QMAttachmentMessageStatusBlock)(QMMessageAttachmentStatus status, QBChatMessage *message);
typedef void (^QMAttachmentMesssageUploadProgressBlock)(float progress, QBChatMessage *message);
typedef void (^QMAttachmentDownloadProgressBlock)(float progress, QBChatMessage *message, QBChatAttachment *attachment);
typedef void (^QMAttachmentDataCompletionBlock)(NSString *attachmentID, NSData * _Nullable data, NSError * _Nullable error);
typedef void (^QMAttachmentProgressBlock)(float progress);
typedef void (^QMAttachmentUploadCompletionBlock)(NSString * _Nullable attachmentID, NSError * _Nullable error);
typedef void(^QMMediaInfoServiceCompletionBlock)(UIImage * _Nullable image, Float64 durationInSeconds, CGSize size, NSError * _Nullable error, NSString *messageID, BOOL cancelled);



NS_ASSUME_NONNULL_END

