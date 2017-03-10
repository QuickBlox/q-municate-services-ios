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
@class QMMediaInfo;

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

- (void)imageForMediaItem:(QMMediaItem *)mediaItem  completion:(void(^)(UIImage *image))completion;

@end

