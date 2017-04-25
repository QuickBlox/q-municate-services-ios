//
//  QMMediaService.m
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/8/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import "QMMediaService.h"

#import "QMChatService.h"


#import "QMMediaItem.h"
#import "QMMediaError.h"

#import "QMSLog.h"

#import "QMMediaWebHandler.h"
#import "QMMediaInfoService.h"

#import "QBChatMessage+QMCustomParameters.h"
#import "QMMediaInfo.h"

#import "QBChatAttachment+QMCustomParameters.h"
#import "QBChatAttachment+QMFactory.h"


@interface QMMediaService()

@property (strong, nonatomic) NSMutableDictionary *placeholderItems;
@property (strong, nonatomic) NSMutableArray *mediaItemsInProgress;

@end

@implementation QMMediaService

@synthesize storeService = _storeService;
@synthesize downloadService = _downloadService;
@synthesize uploadService = _uploadService;
@synthesize mediaInfoService = _mediaInfoService;

//MARK: - NSObject

- (instancetype)init {
    
    if (self = [super init]) {
        
        _mediaItemsInProgress = [NSMutableArray array];
        _placeholderItems = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)dealloc {
    
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

//MARK: - QMMediaServiceDelegate

- (void)cancelOperationsForAttachment:(QBChatAttachment *)attachment {
    
    [self.mediaInfoService cancelInfoOperationForKey:attachment.ID];
    
}

- (QBChatAttachment *)placeholderAttachment:(NSString *)messageID {
    QBChatAttachment *mediaItem = self.placeholderItems[messageID];
    return mediaItem;
}

- (QBChatAttachment *)cachedAttachmentWithID:(NSString *)attachmentID {
    
    
    if ([self.mediaItemsInProgress containsObject:attachmentID]) {
        return  nil;
    }
    
    
    return nil;
}

//MARK: Downloading

- (void)getThumbnailImageForTime:(NSURL *)url withCompletion:(void(^)(UIImage *))completion
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        __block UIImage *thumb ;
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
        AVAssetImageGenerator *_generator;
        _generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:playerItem.asset];
        
        AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
            if (result == AVAssetImageGeneratorSucceeded) {
                thumb = [UIImage imageWithCGImage:image];
                NSLog(@"Succesfully generater the thumbnail!!!");
            } else {
                NSLog(@"Failed to generater the thumbnail!!!");
                NSLog(@"Error : %@",error.localizedDescription);
                
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(thumb);
            });
        };
        
        [_generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(2,1)]] completionHandler:handler];
        
    });
    
}

//MARK: Sending message

- (void)sendMessage:(QBChatMessage *)message
           toDialog:(QBChatDialog *)dialog
    withChatService:(QMChatService *)chatService
     withAttachment:(QBChatAttachment *)attachment
         completion:(QBChatCompletionBlock)completion {
    
    NSData *data = [self dataForAttachment:attachment];
    
    NSAssert(data, @"No Data provided for media");
    
    attachment.mediaData = data;
    
    message.attachments = @[attachment];
    self.placeholderItems[message.ID] = attachment;
    
    [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoading forMessage:message];
    __weak typeof(self) weakSelf = self;
    
    [self.uploadService uploadAttachment:attachment withCompletionBlock:^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        message.text = [NSString stringWithFormat:@"%@ attachment", [[attachment stringContentType] capitalizedString]];
        
        [strongSelf.storeService save:attachment];
        
        [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded forMessage:message];
        
        message.attachments = @[attachment];
        [chatService sendMessage:message
                        toDialog:dialog
                   saveToHistory:YES
                   saveToStorage:YES
                      completion:completion];
    } progressBlock:^(float progress) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf changeMessageUploadingProgress:progress forMessage:message];
        
    }];
    
}

//MARK: - Helpers

- (NSData *)dataForAttachment:(QBChatAttachment *)attachment {
    
    if (attachment.contentType == QMMediaContentTypeImage) {
        if (attachment.image) {
            NSData *data = UIImagePNGRepresentation(attachment.image);
            return data;
        }
    }
    
    if (attachment.localURL != nil) {
        NSData *data = [NSData dataWithContentsOfURL:attachment.localURL];
        return data;
    }
    
    return nil;
}


- (void)changeMessageAttachmentStatus:(QMMessageAttachmentStatus)status
                           forMessage:(QBChatMessage *)message {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.onMessageDidChangeAttachmentStatus) {
            self.onMessageDidChangeAttachmentStatus(status, message);
        }
        
    });
    
}

- (void)changeMessageUploadingProgress:(float)progress
                            forMessage:(QBChatMessage *)message {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.onMessageDidChangeUploadingProgress) {
            self.onMessageDidChangeUploadingProgress(progress, message);
        }
    });
}


- (void)changeDownloadingProgress:(float)progress
                       forMessage:(QBChatMessage *)message
                       attachment:(QBChatAttachment *)attachment {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.onMessageDidChangeDownloadingProgress) {
            self.onMessageDidChangeDownloadingProgress(progress, message, attachment);
        }
    });
}


- (void)getFullMediaInfoForItem:(QMMediaItem *)mediaItem
                 withCompletion:(void(^)(NSTimeInterval duration, CGSize size, UIImage *image, NSError *error))completion {
    
    if (mediaItem.contentType == QMMediaContentTypeVideo || mediaItem.contentType == QMMediaContentTypeAudio) {
        
        [self.mediaInfoService mediaInfoForItem:mediaItem completion:^(NSTimeInterval duration, CGSize mediaSize, UIImage *image, NSError *error) {
            
            completion(duration, mediaSize, image, error);
        }];
        
    }
    else {
        completion(0, CGSizeZero,mediaItem.image, nil);
    }
    
}

- (BOOL)shouldDownloadContentForType:(QMMediaContentType)mediaContentType {
    return mediaContentType == QMMediaContentTypeImage || mediaContentType == QMMediaContentTypeAudio;
}

- (void)audioDataForAttachment:(QBChatAttachment *)attachment
                       message:(QBChatMessage *)message
                    completion:(void(^)(BOOL isReady, NSError *error))completion {
    
    if ([self.storeService isSavedLocally:attachment]) {
        completion(YES, nil);
        return;
    }
    else {
        __weak typeof(self) weakSelf = self;
        
        [self.downloadService downloadDataForAttachment:attachment withCompletionBlock:^(NSString *attachmentID, NSData *data, QMMediaError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (data) {
                attachment.mediaData = data;
                [strongSelf.storeService save:attachment];
                completion(YES,nil);
            }
            else {
                completion(NO, error.error);
            }
        } progressBlock:^(float progress) {
            
            [self changeDownloadingProgress:progress
                                 forMessage:nil
                                 attachment:attachment];
        }];
        
    }
}
- (void)imageForAttachment:(QBChatAttachment *)attachment
                   message:(QBChatMessage *)message
                  withSize:(CGSize)size
                completion:(void(^)(UIImage *image, NSError *error))completion {
    
    __weak typeof(self) weakSelf = self;
    [self.storeService localImageForAttachment:attachment completion:^(UIImage *image) {
        
        if (!image) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            if (attachment.status == QMAttachmentStatusLoading || attachment.status == QMAttachmentStatusError) {
                return;
            }
            if (attachment.contentType == QMAttachmentContentTypeImage) {
                
                attachment.status = QMAttachmentStatusLoading;
                
                [strongSelf.downloadService downloadDataForAttachment:attachment withCompletionBlock:^(NSString *attachmentID, NSData *data, QMMediaError *error) {
                    if (data) {
                        attachment.mediaData = data;
                        [strongSelf.storeService save:attachment];
                        completion([UIImage imageWithData:data], nil);
                        attachment.status = QMAttachmentStatusLoaded;
                    }
                    else {
                        attachment.status = QMAttachmentStatusError;
                        completion(nil, error.error);
                    }
                } progressBlock:^(float progress) {
                    
                    [self changeDownloadingProgress:progress
                                         forMessage:nil
                                         attachment:attachment];
                }];
            }
            else if (attachment.contentType == QMAttachmentContentTypeVideo) {
                
                if (attachment.status == QMAttachmentStatusPreparing || attachment.status == QMAttachmentStatusError) {
                    return;
                }
                
                attachment.status = QMAttachmentStatusPreparing;
                [strongSelf.mediaInfoService videoThumbnailForAttachment:attachment completion:^(UIImage *image, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (image) {
                            attachment.mediaData = UIImagePNGRepresentation(image);
                            [strongSelf.storeService save:attachment];
                            attachment.status = QMAttachmentStatusPrepared;
                        }
                        else {
                            attachment.status = QMAttachmentStatusError;
                        }
                        completion(image, error);
                    });
                }];
            }
        }
        else {
            if (completion) {
                completion(image, nil);
            }
        }
    }];
}

@end
