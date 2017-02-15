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

@protocol QMMediaServiceDelegate <NSObject>

@property (nonatomic, strong) id <QMMediaStoreServiceDelegate> storeService;
@property (nonatomic, strong) id <QMMediaDownloadServiceDelegate> downloadService;
@property (nonatomic, strong) id <QMMediaUploadServiceDelegate> uploadService;


- (void)mediaForMessage:(QBChatMessage *)message
    withCompletionBlock:(void(^)(QMMediaItem *mediaItem, NSError *error))completion;

- (void)sendMessage:(QBChatMessage *)message
           toDialog:(QBChatDialog *)dialog
    withChatService:(QMChatService *)chatService
          withMedia:(QMMediaItem *)mediaItem
         completion:(QBChatCompletionBlock)completion;

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

