//
//  QMMediaServiceDelegate.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/8/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>


@class QMMediaItem;
@class QMChatService;

@protocol QMMediaStoreServiceDelegate;
@protocol QMMediaDownloadServiceDelegate;
@protocol QMMediaUploadServiceDelegate;

typedef void (^QMMediaCompletionBlock)(QMMediaItem *);

typedef void (^QMMessageUploadProgressBlock)(float progress);
typedef void (^QMMessageUploadCompletionBlock)(QMMediaItem *mediaItem, NSError *error);

@protocol QMMediaServiceDelegate <NSObject>

@property (nonatomic, strong) id <QMMediaStoreServiceDelegate> storeService;
@property (nonatomic, strong) id <QMMediaDownloadServiceDelegate> downloadService;
@property (nonatomic, strong) id <QMMediaUploadServiceDelegate> uploadService;


- (void)mediaForMessage:(QBChatMessage *)message
    withCompletionBlock:(void(^)(NSArray<QMMediaItem *> *mediaArray))completion;

- (void)sendMessage:(QBChatMessage *)message
           toDialog:(QBChatDialog *)dialog
    withChatService:(QMChatService *)chatService
          withMedia:(QMMediaItem *)mediaItem
         completion:(QBChatCompletionBlock)completion;

- (void)addUploadListenerForMessageWithID:(NSString *)messageID
                          completionBlock:(QMMessageUploadCompletionBlock)completionBlock
                            progressBlock:(QMMessageUploadProgressBlock)progressBlock;

@optional

- (BOOL)isReadyToPlay:(NSString *)mediaID contentType:(NSString *)contentType;

@end

