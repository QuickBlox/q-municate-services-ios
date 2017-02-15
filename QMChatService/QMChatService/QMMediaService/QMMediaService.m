//
//  QMMediaService.m
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/8/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import "QMMediaService.h"

#import "QMChatService.h"

#import "QMMediaStoreServiceDelegate.h"
#import "QMMediaDownloadServiceDelegate.h"
#import "QMMediaUploadServiceDelegate.h"

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
            globalDownloadCompletionBlock(message.ID, mediaID, data, error, strongSelf);
            
        } progressBlock:^(float progress) {
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            globalDownloadProgressBlock(message.ID, attachment.ID, progress, strongSelf);
        }];
    }
}


- (void)mediaForMessage:(QBChatMessage *)message
    withCompletionBlock:(void(^)(NSArray<QMMediaItem *> *array))completion {
    
    if (message.attachmentStatus == QMMessageAttachmentStatusLoading || message.attachmentStatus == QMMessageAttachmentStatusError) {
        return;
    }
    
    if (message.attachments.count) {
        
        QBChatAttachment *attachment = message.attachments[0];
        
        //Check for item in local storage
        QMMediaItem *mediaItem = [self.storeService mediaItemFromAttachment:attachment];
        
        
        if (!mediaItem) {
            
            // loading attachment from server
            [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoading forMessage:message];
            
            
            __weak typeof(self) weakSelf = self;
            
            [self.downloadService downloadMediaItemWithID:attachment.ID withCompletionBlock:^(NSString *mediaID, NSData *data, QMMediaError *error) {
                
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                
                QMMediaItem *item = nil;
                
                if (!error) {
                    
                    item = [[QMMediaItem alloc] init];
                    [item updateWithAttachment:attachment];
                    item.data = data;
                    [strongSelf.storeService saveMediaItem:item];
                    
                    [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded forMessage:message];
                    
                    if (completion) {
                        completion(@[item]);
                    }
                }
                else {
                    [strongSelf changeMessageAttachmentStatus:error.attachmentStatus forMessage:message];
                }
                
                globalDownloadCompletionBlock(message.ID, mediaID, data, error, strongSelf);
                
            } progressBlock:^(float progress) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                globalDownloadProgressBlock(message.ID, attachment.ID, progress, strongSelf);
            }];
        }
        else {
            
            if (completion) {
                completion(@[mediaItem]);
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
    
    NSData *data = [self dataForMediaItem:mediaItem];
    NSAssert(data,@"NO Data provided for media");
    
    __weak typeof(self) weakSelf = self;
    
    [self.uploadService uploadMediaWithData:data
                                   mimeType:[mediaItem stringMIMEType]
                        withCompletionBlock:^(QBCBlob *blob, NSError *error) {
                            
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            
                            QBChatAttachment *attachment = [QBChatAttachment new];
                            attachment.type = [mediaItem stringMediaType];
                            attachment.ID = blob.UID;
                            attachment.url = [blob privateUrl];
                            message.attachments = @[attachment];
                            
                            [mediaItem updateWithAttachment:attachment];
                            
                            message.text = [NSString stringWithFormat:@"Attachment %@",[mediaItem stringMediaType]];
                            
                            [strongSelf.storeService saveMediaItem:mediaItem];
                            
                            globalUploadCompletionBlock(message.ID, mediaItem, error, strongSelf);
                            
                            [chatService sendMessage:message toDialog:dialog saveToHistory:YES saveToStorage:YES completion:completion];
                            
                        } progressBlock:^(float progress) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
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


- (BOOL)isReadyToPlay:(QMMediaItem *)item {
    
    return [self.storeService isReadyToPlay:item.mediaID contentType:item.stringMediaType];
}



- (BOOL)isReadyToPlay:(NSString *)mediaID contentType:(NSString *)contentType {
    
    return [self.storeService isReadyToPlay:mediaID contentType:contentType];
}

//MARK:-  Global Blocks
//MARK:  Global Blocks
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
    
    message.attachmentStatus = status;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([self.attachmentService.delegate respondsToSelector:@selector(chatAttachmentService:didChangeAttachmentStatus:forMessage:)]) {
            [self.attachmentService.delegate chatAttachmentService:self.attachmentService didChangeAttachmentStatus:status forMessage:message];
        }
        
    });
}



@end
