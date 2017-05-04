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


- (void)sendMessage:(QBChatMessage *)message
           toDialog:(QBChatDialog *)dialog
    withChatService:(QMChatService *)chatService
     withAttachment:(QBChatAttachment *)attachment
         completion:(QBChatCompletionBlock)completion;

- (QBChatAttachment *)cachedAttachmentWithID:(NSString *)attachmentID
                                forMessageID:(NSString *)messageID;


- (void)imageForMediaItem:(QMMediaItem *)mediaItem  completion:(void(^)(UIImage *image))completion;




@end

