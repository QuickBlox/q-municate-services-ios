//
//  QMMediaServiceDelegate.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/8/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMMediaBlocks.h"

@class QMMediaItem;
@class QMChatService;

@protocol QMMediaStoreServiceDelegate;
@protocol QMMediaDownloadServiceDelegate;
@protocol QMMediaUploadServiceDelegate;
@protocol QMMediaInfoServiceDelegate;

@protocol QMMediaServiceDelegate <NSObject>

@property (nonatomic, strong) id <QMMediaStoreServiceDelegate> storeService;
@property (nonatomic, strong) id <QMMediaDownloadServiceDelegate> downloadService;
@property (nonatomic, strong) id <QMMediaUploadServiceDelegate> uploadService;
@property (nonatomic, strong) id <QMMediaInfoServiceDelegate> mediaInfoService;

- (void)mediaForMessage:(QBChatMessage *)message
           attachmentID:(NSString *)attachmentID
    withCompletionBlock:(void(^)(QMMediaItem *mediaItem, NSError *error))completion;

- (void)sendMessage:(QBChatMessage *)message
           toDialog:(QBChatDialog *)dialog
    withChatService:(QMChatService *)chatService
          withMedia:(QMMediaItem *)mediaItem
         completion:(QBChatCompletionBlock)completion;

- (QMMediaItem *)cachedMediaForMessage:(QBChatMessage *)message attachmentID:(NSString *)attachmentID;

- (void)addUploadListenerForMessageWithID:(NSString *)messageID
                          completionBlock:(QMMessageUploadCompletionBlock)completionBlock
                            progressBlock:(QMMessageUploadProgressBlock)progressBlock;

- (void)addDownloadListenerForItemWithID:(NSString *)mediaItemID
                         completionBlock:(QMMediaRestCompletionBlock)completionBlock
                           progressBlock:(QMMediaProgressBlock)progressBlock;

- (void)addStatusListenerForMessageWithID:(NSString *)messageID
                              statusBlock:(void(^)(QMMessageAttachmentStatus))statusBlock;

@optional

- (BOOL)isReadyToPlay:(QMMediaItem *)item;

@end

