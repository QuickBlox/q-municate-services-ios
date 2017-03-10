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

#import "QMMediaDownloadDelegate.h"
#import "QMMediaWebServiceDelegate.h"
#import "QMMediaWebHandler.h"
#import "QMMediaInfoService.h"

#import "QBChatMessage+QMCustomParameters.h"
#import "QMMediaInfo.h"
#import "QBChatAttachment+QMMediaItem.h"

@interface QMMediaService()

@property (strong, nonatomic) NSMutableDictionary *messageUploadHandlers;
@property (strong, nonatomic) NSMutableDictionary *messageDownloadHandlers;
@property (strong, nonatomic) NSMutableDictionary *messageStatusHandlers;


@property (strong, nonatomic) NSMutableDictionary *placeholderItems;

@property (strong, nonatomic) NSMutableArray *mediaItemsInProgress;

@property (strong, nonatomic) dispatch_queue_t barrierQueue;

@end


@implementation QMMediaService

@synthesize storeService = _storeService;
@synthesize downloadService = _downloadService;
@synthesize uploadService = _uploadService;
@synthesize mediaInfoService = _mediaInfoService;

//MARK: - NSObject

- (instancetype)init {
    
    if (self = [super init]) {
        
        _messageUploadHandlers = [NSMutableDictionary dictionary];
        _messageDownloadHandlers = [NSMutableDictionary dictionary];
        _mediaItemsInProgress = [NSMutableArray array];
        _barrierQueue = dispatch_queue_create("com.quickblox.QMMediaService", DISPATCH_QUEUE_CONCURRENT);
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
            mediaItem = [self.storeService mediaItemFromAttachment:currentAttachment];
        }
    }
    
    return mediaItem;
}

//MARK: Downloading

- (void)mediaForMessage:(QBChatMessage *)message
           attachmentID:(NSString *)attachmentID
    withCompletionBlock:(void(^)(QMMediaItem *mediaItem, NSError *error))completion {
    
    if (message.attachmentStatus == QMMessageAttachmentStatusLoading || message.attachmentStatus == QMMessageAttachmentStatusError) {
        return;
    }
    
    if ([self.mediaItemsInProgress containsObject:attachmentID]) {
        return;
    }
    
    if (message.attachments.count) {
        
        QBChatAttachment *attachment = message.attachments[0];
        
        //Check for item in local storage
        QMMediaItem *mediaItem = [self cachedMediaForMessage:message attachmentID:attachmentID];
        
        if (!mediaItem && attachment) {
            
            mediaItem = [QMMediaItem new];
            [mediaItem updateWithAttachment:attachment];
            
            // loading attachment from server
            [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoading forMessage:message];
            
            if (mediaItem.contentType != QMMediaContentTypeVideo) {
                
                [self.mediaItemsInProgress addObject:attachmentID];
                
                __weak typeof(self) weakSelf = self;
                [self.downloadService downloadMediaItemWithID:attachment.ID
                                          withCompletionBlock:^(NSString *mediaID, NSData *data, QMMediaError *error) {
                                              
                                              __strong typeof(weakSelf) strongSelf = weakSelf;
                                              
                                              QMMediaItem *item = nil;
                                              
                                              if (!error) {
                                                  
                                                  item = [[QMMediaItem alloc] init];
                                                  [item updateWithAttachment:attachment];
                                                  
                                                  item.data = data;
                                                  
                                                  [strongSelf.storeService saveMediaItem:item];
                                                  
                                                  
                                                  [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded forMessage:message];
                                                  
                                                  completion(mediaItem, nil);
                                              }
                                              else {
                                                  
                                                  [strongSelf changeMessageAttachmentStatus:error.attachmentStatus forMessage:message];
                                                  completion(nil, error.error);
                                              }
                                              
                                              [self.mediaItemsInProgress removeObject:mediaID];
                                              
                                          } progressBlock:^(float progress) {
                                              
                                              __strong typeof(weakSelf) strongSelf = weakSelf;
                                              [strongSelf changeDownloadingProgress:progress forMessage:message attachment:attachment];
                                              
                                          }];
            }
            else {
                
                if (completion) {
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

//MARK: Sending message

- (void)sendMessage:(QBChatMessage *)message
           toDialog:(QBChatDialog *)dialog
    withChatService:(QMChatService *)chatService
          withMedia:(QMMediaItem *)mediaItem
         completion:(QBChatCompletionBlock)completion {
    
    dispatch_group_t mediaInfoGroup = dispatch_group_create();
    
    if (mediaItem.contentType == QMMediaContentTypeVideo) {
        
        QMMediaInfo *mediaInfo = [QMMediaInfo infoFromMediaItem:mediaItem];
        
        dispatch_group_enter(mediaInfoGroup);
        
        [mediaInfo prepareWithCompletion:^(NSError *error) {
            
            __weak typeof(self) weakSelf = self;
            
            [self.mediaInfoService thumbnailForMediaWithURL:mediaItem.localURL completion:^(UIImage *image) {
                
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                mediaItem.mediaDuration = mediaInfo.duration;
                mediaItem.mediaSize = mediaInfo.mediaSize;
                mediaItem.image = image;
                
                dispatch_group_leave(mediaInfoGroup);
            }];
        }];
    }
    
    __weak __typeof(self)weakSelf = self;
    
    dispatch_group_notify(mediaInfoGroup, dispatch_get_main_queue(), ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        QBChatAttachment *tempAttachment = [QBChatAttachment new];
        [tempAttachment updateWithMediaItem:mediaItem];
        
        NSData *data = [strongSelf dataForMediaItem:mediaItem];
        
        NSAssert(data, @"No Data provided for media");
        strongSelf.placeholderItems[message.ID] = mediaItem;
        message.attachments = @[tempAttachment];
        
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
                                          
                                          [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusNotLoaded forMessage:message];
                                          completion(error);
                                          return;
                                      }
                                      
                                      QBChatAttachment *attachment = [QBChatAttachment new];
                                      attachment.type = [mediaItem stringContentType];
                                      attachment.ID = blob.UID;
                                      attachment.url = [blob privateUrl];
                                      
                                      [mediaItem updateWithAttachment:attachment];
                                      
                                      message.attachments = @[attachment];
                                      
                                      message.text = [NSString stringWithFormat:@"Attachment %@",[mediaItem stringContentType]];
                                      
                                      mediaItem.data = data;
                                      
                                      [strongSelf.storeService saveMediaItem:mediaItem];
                                      
                                      globalUploadCompletionBlock(message.ID, mediaItem, error, strongSelf);
                                      
                                      [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded forMessage:message];
                                      
                                      [chatService sendMessage:message toDialog:dialog saveToHistory:YES saveToStorage:YES completion:completion];
                                      
                                  } progressBlock:^(float progress) {
                                      
                                      __strong typeof(weakSelf) strongSelf = weakSelf;
                                      [strongSelf changeMessageUploadingProgress:progress forMessage:message];
                                      globalUploadProgressBlock(message.ID, progress, strongSelf);
                                  }];
    });
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



//MARK:-  Global Blocks

void (^globalUploadProgressBlock)(NSString *messageID,float progress, QMMediaService *mediaService) =
^(NSString *messageID, float progress, QMMediaService *mediaService) {
    
    __block NSArray *handlers;
    dispatch_sync(mediaService.barrierQueue, ^{
        handlers = [[mediaService.messageUploadHandlers objectForKey:messageID] copy];
    });
    
    //Inform the handlers
    [handlers enumerateObjectsUsingBlock:^(QMMessageUploadHandler *handler, NSUInteger idx, BOOL *stop) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(handler.progressBlock) {
                handler.progressBlock(progress);
            }
        });
    }];
};

void (^globalUploadCompletionBlock)(NSString *messageID, QMMediaItem *mediaItem, NSError *error, QMMediaService *mediaService) =
^(NSString *messageID, QMMediaItem *mediaItem, NSError *error, QMMediaService *mediaService)
{
    __block NSArray *handlers;
    
    dispatch_barrier_sync(mediaService.barrierQueue, ^{
        handlers = [[mediaService.messageUploadHandlers objectForKey:messageID] copy];
        [mediaService.messageUploadHandlers removeObjectForKey:messageID];
    });
    
    //Inform the handlers
    [handlers enumerateObjectsUsingBlock:^(QMMessageUploadHandler *handler, NSUInteger idx, BOOL *stop) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler.completionBlock) {
                handler.completionBlock(mediaItem, error);
            }
        });
    }];
    
};


void (^globalDownloadProgressBlock)(NSString *messageID, NSString *mediaID, float progress, QMMediaService *mediaService) =
^(NSString *messageID, NSString *mediaID, float progress, QMMediaService *mediaService)
{
    
};

void (^globalDownloadCompletionBlock)(NSString *messageID, NSString *mediaID, NSData *mediaData, QMMediaError *error, QMMediaService *mediaService) =
^(NSString *messageID, NSString *mediaID, NSData *mediaData, QMMediaError *error, QMMediaService *mediaService)
{
    NSMutableArray *handlers = [mediaService.messageDownloadHandlers objectForKey:messageID];
    //Inform the handlers
    [handlers enumerateObjectsUsingBlock:^(QMMediaWebHandler *handler, NSUInteger idx, BOOL *stop) {
        
    }];
};

- (void)changeMessageAttachmentStatus:(QMMessageAttachmentStatus)status forMessage:(QBChatMessage *)message {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.onMessageDidChangeAttachmentStatus) {
            self.onMessageDidChangeAttachmentStatus(status, message);
        }
        
    });
    
}

- (void)changeMessageUploadingProgress:(float)progress forMessage:(QBChatMessage *)message {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.onMessageDidChangeUploadingProgress) {
            self.onMessageDidChangeUploadingProgress(progress, message);
        }
    });
}
- (void)changeDownloadingProgress:(float)progress forMessage:(QBChatMessage *)message attachment:(QBChatAttachment *)attachment {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.onMessageDidChangeDownloadingProgress) {
            self.onMessageDidChangeDownloadingProgress(progress, message, attachment);
        }
    });
}




@end
