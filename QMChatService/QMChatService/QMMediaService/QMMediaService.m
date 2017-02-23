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

#import "QBChatMessage+QMCustomParameters.h"

@interface QMMediaService()

@property (strong, nonatomic) NSMutableDictionary *messageUploadHandlers;
@property (strong, nonatomic) NSMutableDictionary *messageDownloadHandlers;
@property (strong, nonatomic) NSMutableDictionary *messageStatusHandlers;

@property (strong, nonatomic) dispatch_queue_t barrierQueue;

@end


@implementation QMMediaService

@synthesize storeService = _storeService;
@synthesize downloadService = _downloadService;
@synthesize uploadService = _uploadService;


//MARK: - NSObject

- (instancetype)init {
    
    if (self = [super init]) {
        
        _messageUploadHandlers = [NSMutableDictionary dictionary];
        _messageDownloadHandlers = [NSMutableDictionary dictionary];
        
        _barrierQueue = dispatch_queue_create("com.quickblox.QMMediaService", DISPATCH_QUEUE_CONCURRENT);
    }
    
    return self;
}

- (void)dealloc {
    
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}



//MARK: - QMMediaServiceDelegate

//MARK: Uploading
- (void)subscribeToItemWithID:(NSString *)itemID
                    messageID:(NSString *)messageID
                downloadBlock:(void(^)(float))downloadBlock
                  uploadBlock:(void(^)(float))uploadBlock
                      success:(void(^)(QMMediaItem *))successBlock
                        error:(void(^)(NSError *))error {
    
    [self.downloadService addListenerToMediaItemWithID:itemID withCompletionBlock:^(NSString *mediaID, NSData *data, QMMediaError *error) {
        
    } progressBlock:^(float progress) {
        downloadBlock(progress);
    }];
    
    [self addUploadListenerForMessageWithID:messageID completionBlock:^(QMMediaItem *mediaItem, NSError *error) {
        
    } progressBlock:^(float progress) {
        uploadBlock(progress);
    }];
}

- (void)addUploadListenerForMessageWithID:(NSString *)messageID
                          completionBlock:(QMMessageUploadCompletionBlock)completionBlock
                            progressBlock:(QMMessageUploadProgressBlock)progressBlock {
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_barrier_sync(self.barrierQueue, ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        NSMutableArray *handlers = [self.messageUploadHandlers objectForKey:messageID];
        
        if (handlers == nil) {
            handlers = [NSMutableArray new];
        }
        
        QMMessageUploadHandler *handler = [QMMessageUploadHandler uploadingHandlerWithID:messageID
                                                                         completionBlock:completionBlock
                                                                           progressBlock:progressBlock];
        
        [handlers addObject:handler];
        [strongSelf.messageUploadHandlers setObject:handlers forKey:messageID];
    });
    
}

- (void)addDownloadListenerForItemWithID:(NSString *)mediaItemID
                         completionBlock:(QMMediaRestCompletionBlock)completionBlock
                           progressBlock:(QMMediaProgressBlock)progressBlock {
    
    [self.downloadService addListenerToMediaItemWithID:mediaItemID
                                   withCompletionBlock:completionBlock
                                         progressBlock:progressBlock];
}

- (void)addStatusListenerForMessageWithID:(NSString *)messageID
                              statusBlock:(void(^)(QMMessageAttachmentStatus))statusBlock {
    
    
}

- (void)addUploadingListenerForMessage:(QBChatMessage *)message
                       completionBlock:(QMMessageUploadCompletionBlock)completionBlock
                         progressBlock:(QMMessageUploadProgressBlock)progressBlock {
    
    [self addUploadListenerForMessageWithID:message.ID
                            completionBlock:completionBlock
                              progressBlock:progressBlock];
}

//MARK: Downloading

- (void)addDownloadListenerForMessage:(QBChatMessage *)message
                      completionBlock:(void(^)(QMMediaItem *item, NSError *error, BOOL finished ))completion
                        progressBlock:(void(^)(NSString *mediaID, float progress))progressBlock {
    
    for (QBChatAttachment *attachment in message.attachments) {
        
        __weak typeof(self) weakSelf = self;
        
        [self.downloadService addListenerToMediaItemWithID:attachment.ID withCompletionBlock:^(NSString *mediaID, NSData *data, QMMediaError *error) {
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            globalDownloadCompletionBlock(message.ID, mediaID, data, error.error, strongSelf);
            
        } progressBlock:^(float progress) {
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            globalDownloadProgressBlock(message.ID, attachment.ID, progress, strongSelf);
        }];
    }
}


- (QMMediaItem *)cachedMediaForMessage:(QBChatMessage *)message {
    
    QMMediaItem *mediaItem = nil;
    
    if (message.attachmentStatus == QMMessageAttachmentStatusLoading || message.attachmentStatus == QMMessageAttachmentStatusError) {
        return  nil;
    }
    
    else if (message.attachments.count) {
        
        QBChatAttachment *attachment = message.attachments[0];
        mediaItem = [self.storeService mediaItemFromAttachment:attachment];
    }
    
    return mediaItem;
}

- (void)mediaForMessage:(QBChatMessage *)message
    withCompletionBlock:(void(^)(QMMediaItem *mediaItem, NSError *error))completion {
    
    
    if (message.attachmentStatus == QMMessageAttachmentStatusLoading || message.attachmentStatus == QMMessageAttachmentStatusError) {
        return;
    }
    
    if (message.attachments.count) {
        
        QBChatAttachment *attachment = message.attachments[0];
        
        //Check for item in local storage
        QMMediaItem *mediaItem = [self.storeService mediaItemFromAttachment:attachment];
        
        if (!mediaItem && attachment) {
            
            // loading attachment from server
            [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoading forMessage:message];
            
            
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
                                              
                                          }
                                          else {
                                              
                                              [strongSelf changeMessageAttachmentStatus:error.attachmentStatus forMessage:message];
                                          }
                                          
                                          completion(item, error.error);
                                          
                                          globalDownloadCompletionBlock(message.ID, mediaID, data, error, strongSelf);
                                          
                                      } progressBlock:^(float progress) {
                                          
                                          __strong typeof(weakSelf) strongSelf = weakSelf;
                                          [strongSelf changeDownloadingProgress:progress forMessage:message attachment:attachment];
                                          globalDownloadProgressBlock(message.ID, attachment.ID, progress, strongSelf);
                                      }];
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
    
    QBChatAttachment *tempAttachment = [QBChatAttachment new];
    
    tempAttachment.type = [mediaItem stringContentType];
    message.attachments = @[tempAttachment];
    
    [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoading forMessage:message];
    
    NSData *data = [self dataForMediaItem:mediaItem];
    
    NSAssert(data, @"No Data provided for media");
    
    __weak typeof(self) weakSelf = self;
    
    [self.uploadService uploadMediaWithData:data
                                   mimeType:[mediaItem stringMIMEType]
                        withCompletionBlock:^(QBCBlob *blob, NSError *error) {
                            
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            NSMutableArray *messageAttachments = message.attachments.mutableCopy;
                            
                            for (QBChatAttachment *attachment in message.attachments) {
                                if ([attachment isEqual:tempAttachment]) {
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
                            
                            [strongSelf.storeService saveMediaItem:mediaItem];
                            
                            globalUploadCompletionBlock(message.ID, mediaItem, error, strongSelf);
                            
                             [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded forMessage:message];
                            
                            [chatService sendMessage:message toDialog:dialog saveToHistory:YES saveToStorage:YES completion:completion];
                            
                        } progressBlock:^(float progress) {
                            
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            [strongSelf changeMessageUploadingProgress:progress forMessage:message];
                            globalUploadProgressBlock(message.ID, progress, strongSelf);
                        }];
    
}

//MARK: - Helpers

- (NSData *)dataForMediaItem:(QMMediaItem *)item {
    
    if (item.data) {
        return item.data;
    }
    if (item.localURL != nil) {
        NSData *data = [NSData dataWithContentsOfURL:item.localURL];
        return data;
    }
    
    
    return nil;
}


//- (BOOL)isReadyToUse:(QBChatAttachment *)attachment {
//    
//    return [self.storeService isReadyToUse:attachment ];
//}

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
