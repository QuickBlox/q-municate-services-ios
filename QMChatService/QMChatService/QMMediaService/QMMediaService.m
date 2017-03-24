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

- (QMMediaItem *)placeholderMediaForMessage:(QBChatMessage *)message {
    
    QMMediaItem *mediaItem = self.placeholderItems[message.ID];
    return mediaItem;
}

- (QMMediaItem *)cachedMediaForMessage:(QBChatMessage *)message attachmentID:(NSString *)attachmentID {
    
    QMMediaItem *mediaItem = nil;
    
    if ([self.mediaItemsInProgress containsObject:attachmentID]) {
        return  nil;
    }
    
    else if (message.attachments.count) {
        
        QBChatAttachment *currentAttachment = nil;
        for (QBChatAttachment *attachment in message.attachments) {
            if ([attachment.ID isEqualToString:attachmentID]) {
                currentAttachment = attachment;
                break;
            }
        }
        
        if (currentAttachment) {
            return mediaItem = [self.storeService mediaItemFromAttachment:currentAttachment];
        }
    }
    
    return nil;
}

//MARK: Downloading

- (void)mediaForMessage:(QBChatMessage *)message
           attachmentID:(NSString *)attachmentID
    withCompletionBlock:(void(^)(QMMediaItem *mediaItem, NSError *error))completion {
    
    if (message.attachmentStatus == QMMessageAttachmentStatusLoading || message.attachmentStatus == QMMessageAttachmentStatusError) {
        return;
    }
    
    if (message.attachments.count) {
        
        
        QBChatAttachment *attachment = message.attachments[0];
        
        //Check for item in local storage
        QMMediaItem *mediaItem = [self cachedMediaForMessage:message attachmentID:attachmentID];
        
        if (!mediaItem) {
            
            mediaItem = [QMMediaItem mediaItemWithAttachment:attachment];
            
            if ([self shouldDownloadContentForType:mediaItem.contentType]) {
                
                // loading attachment from server
                [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoading forMessage:message];
                
                [self.mediaItemsInProgress addObject:attachmentID];
                
                __weak typeof(self) weakSelf = self;
                [self.downloadService downloadMediaItemWithID:attachment.ID
                                          withCompletionBlock:^(NSString *mediaID, NSData *data, QMMediaError *error) {
                                              
                                              __strong typeof(weakSelf) strongSelf = weakSelf;
                                              
                                              if (!error) {
                                                  mediaItem.data = data;
                                                  
                                                  dispatch_block_t completionBlock = ^{
                                                      mediaItem.localURL = [strongSelf.storeService saveMediaItem:mediaItem];
                                                      [strongSelf.mediaItemsInProgress removeObject:mediaID];
                                                      [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded forMessage:message];
                                                      completion(mediaItem, nil);
                                                  };
                                                  /*
                                                   if (![mediaItem isReady]) {
                                                   [strongSelf getFullMediaInfoForItem:mediaItem withCompletion:^(NSTimeInterval duration, CGSize size, UIImage *image, NSError *error) {
                                                   if (!error) {
                                                   if (image) {
                                                   mediaItem.image = image;
                                                   }
                                                   mediaItem.mediaDuration = duration;
                                                   mediaItem.mediaSize = size;
                                                   }
                                                   
                                                   completionBlock();
                                                   
                                                   }];
                                                   }
                                                   else {*/
                                                  completionBlock();
                                                  
                                              }
                                              else {
                                                  
                                                  [strongSelf changeMessageAttachmentStatus:error.attachmentStatus forMessage:message];
                                                  [strongSelf.mediaItemsInProgress removeObject:mediaID];
                                                  completion(nil, error.error);
                                              }
                                              
                                          } progressBlock:^(float progress) {
                                              
                                              __strong typeof(weakSelf) strongSelf = weakSelf;
                                              [strongSelf changeDownloadingProgress:progress forMessage:message attachment:attachment];
                                              
                                          }];
            }
            else {
                if (mediaItem.contentType == QMMediaContentTypeVideo) {
                 /*  __weak typeof(self) weakSelf = self;
                    
                     [self getFullMediaInfoForItem:mediaItem withCompletion:^(NSTimeInterval duration, CGSize size, UIImage *image, NSError *error) {
                     __strong typeof(weakSelf) strongSelf = weakSelf;
                     if (!error) {
                     if (image) {
                     mediaItem.image = image;
                     }
                     mediaItem.mediaDuration = duration;
                     mediaItem.mediaSize = size;
                     }
                     [strongSelf.storeService saveMediaItem:mediaItem];
                     completion(mediaItem, nil);
                     }];
                     */
                    /*
                     [self.mediaItemsInProgress addObject:attachmentID];
                     
                     
                     
                    
                    NSLog(@"remoteURL = %@", mediaItem.remoteURL);
                    
                    [self.mediaInfoService thumbnailImageForMedia:mediaItem completion:^(UIImage *image, NSError *error) {
                        __strong typeof(weakSelf) strongSelf = weakSelf;
                        if (!error) {
                            if (image) {
                                mediaItem.image = image;
                            }
                        }
                        //   [strongSelf.storeService saveMediaItem:mediaItem];
                        completion(mediaItem, nil);
                    }];
                    */
                    completion(mediaItem, nil);
                }
            }
        }
        else {
            if (completion) {
                completion(mediaItem, nil);
            }
        }
        
    }
}

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
          withMedia:(QMMediaItem *)mediaItem
         completion:(QBChatCompletionBlock)completion {
    
    __weak __typeof(self)weakSelf = self;
    
    
    [self getFullMediaInfoForItem:mediaItem withCompletion:^(NSTimeInterval duration, CGSize size, UIImage *image, NSError *error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!error) {
            if (image) {
                mediaItem.image = image;
            }
            mediaItem.mediaDuration = duration;
            mediaItem.mediaSize = size;
        }
        
        
        NSData *data = [strongSelf dataForMediaItem:mediaItem];
        
        NSAssert(data, @"No Data provided for media");
        
        message.attachments = @[mediaItem.attachment];
        strongSelf.placeholderItems[message.ID] = mediaItem;
        
        [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusLoading forMessage:message];
        
        [strongSelf.uploadService uploadMediaWithData:data
                                             mimeType:[mediaItem stringMIMEType]
                                  withCompletionBlock:^(QBCBlob *blob, NSError *error) {
                                      
                                      NSMutableArray *messageAttachments = message.attachments.mutableCopy;
                                      
                                      for (QBChatAttachment *attachment in message.attachments) {
                                          
                                          if (attachment.ID == nil) {
                                              [messageAttachments removeObject:attachment];
                                          }
                                      }
                                      
                                      message.attachments = messageAttachments.copy;
                                      
                                      if (error && completion) {
                                          
                                          completion(error);
                                          return;
                                      }
                                      
                                      mediaItem.mediaID = blob.UID;
                                      mediaItem.attachment.size = blob.size;
                                      mediaItem.data = data;
                                      message.attachments = @[mediaItem.attachment];
                                      message.text = [NSString stringWithFormat:@"%@ attachment", [[mediaItem stringContentType] capitalizedString]];
                                      
                                      NSURL *localURL = [strongSelf.storeService saveMediaItem:mediaItem];
                                      if (localURL != nil) {
                                          mediaItem.localURL = localURL;
                                      }
                                      if (mediaItem.contentType == QMMediaContentTypeVideo) {
                                          UIImage *image = mediaItem.image;
                                          [strongSelf.mediaInfoService saveThumbnailImage:image
                                                                             forMediaItem:mediaItem];
                                      }
                                      
                                      [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded forMessage:message];
                                      
                                      [chatService sendMessage:message
                                                      toDialog:dialog
                                                 saveToHistory:YES
                                                 saveToStorage:YES
                                                    completion:completion];
                                      
                                  } progressBlock:^(float progress) {
                                      
                                      __strong typeof(weakSelf) strongSelf = weakSelf;
                                      [strongSelf changeMessageUploadingProgress:progress forMessage:message];
                                  }];
    }];
}


//MARK: - Helpers

- (NSData *)dataForMediaItem:(QMMediaItem *)item {
    
    if (item.contentType == QMMediaContentTypeImage) {
        if (item.image) {
            NSData *data = UIImagePNGRepresentation(item.image);
            return data;
        }
    }
    
    if (item.localURL != nil) {
        NSData *data = [NSData dataWithContentsOfURL:item.localURL];
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


@end
