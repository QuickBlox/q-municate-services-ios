//
//  QMMediaService.m
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/8/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import "QMMediaService.h"
#import "QMChatService.h"
#import "QMMediaServiceDelegate.h"

#import "QMMediaStoreServiceDelegate.h"
#import "QMMediaDownloadServiceDelegate.h"
#import "QMMediaUploadServiceDelegate.h"

#import "QMMediaItem.h"
#import "QMSLog.h"
#import "EXTScope.h"

#import <QuickBlox/QBMulticastDelegate.h>
#import "QMMediaDownloadDelegate.h"
#import "QMMediaWebServiceDelegate.h"
#import "QMMediaWebHandler.h"

@interface QMMessageUploadHandler : NSObject

@property (nonatomic, copy) NSString *handlerID;
@property (nonatomic, copy) QMMessageUploadProgressBlock progressBlock;
@property (nonatomic, copy) QMMessageUploadCompletionBlock completionBlock;

@property (nonatomic, weak) id<QMMediaDownloadDelegate> delegate;

+ (QMMessageUploadHandler *)uploadingHandlerWithID:(NSString *)handlerID
                                  progressBlock:(QMMessageUploadProgressBlock)progressBlock
                                completionBlock:(QMMessageUploadCompletionBlock)completionBlock;
@end

@implementation QMMessageUploadHandler

+ (QMMessageUploadHandler *)uploadingHandlerWithID:(NSString *)handlerID
                                progressBlock:(QMMessageUploadProgressBlock)progressBlock
                              completionBlock:(QMMessageUploadCompletionBlock)completionBlock {
    
    QMMessageUploadHandler *mediaHandler = [QMMessageUploadHandler new];
    mediaHandler.handlerID = handlerID;
    mediaHandler.progressBlock = progressBlock;
    mediaHandler.completionBlock = completionBlock;
    
    return mediaHandler;
}

@end

@interface QMMediaService()

@property (strong, nonatomic) NSMutableDictionary *messageUploadHandlers;
@property (strong, nonatomic) NSMutableDictionary *messageDownloadHandlers;

@end


@implementation QMMediaService

@synthesize storeService = _storeService;
@synthesize downloadService = _downloadService;
@synthesize uploadService = _uploadService;

- (void)dealloc {
    
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (instancetype)init {
    
    if (self = [super init]) {
        _messageUploadHandlers = [NSMutableDictionary dictionary];
        _messageDownloadHandlers = [NSMutableDictionary dictionary];
    }
    
    return self;
}


//MARK: - QMMediaServiceDelegate

- (void)addUploadListenerForMessageWithID:(NSString *)messageID completionBlock:(QMMessageUploadCompletionBlock)completionBlock progressBlock:(QMMessageUploadProgressBlock)progressBlock {
    
    NSMutableArray *handlers = [self.messageUploadHandlers objectForKey:messageID];
    
    if (handlers == nil) {
        handlers = [NSMutableArray new];
    }
    
    QMMessageUploadHandler *handler = [QMMessageUploadHandler uploadingHandlerWithID:messageID
                                                                       progressBlock:progressBlock
                                                                     completionBlock:completionBlock];
    
    [handlers addObject:handler];
    [self.messageUploadHandlers setObject:handlers forKey:messageID];
}

- (void)mediaForMessage:(QBChatMessage *)message
    withCompletionBlock:(void(^)(NSArray<QMMediaItem *> *array))completion {
    
    if (message.attachments.count) {
        
        QBChatAttachment *attachment = message.attachments[0];
        
        //Check for item in local storage
        QMMediaItem *mediaItem = [self.storeService mediaItemFromAttachment:attachment];
        
        if (!mediaItem) {
            [self.downloadService downloadMediaItemWithID:attachment.ID withCompletionBlock:^(NSString *mediaID, NSData *data, NSError *error) {
                
                QMMediaItem *item = nil;
                if (!error) {
                    QMMediaItem *item = [[QMMediaItem alloc] init];
                    [item updateWithAttachment:attachment];
                    item.data = data;
                    [self.storeService saveMediaItem:item];
                    
                    if (completion) {
                        completion(@[item]);
                    }
                }
            
                globalDownloadCompletionBlock(message.ID, mediaID, data, error, self);
                
            } progressBlock:^(float progress) {
                globalDownloadProgressBlock(message.ID, attachment.ID, progress, self);
            }];
        }
        else {
            if (completion) {
                completion(@[mediaItem]);
            }
        }
        
    }
}



- (void)sendMessage:(QBChatMessage *)message
           toDialog:(QBChatDialog *)dialog
    withChatService:(QMChatService *)chatService
          withMedia:(QMMediaItem *)mediaItem
         completion:(QBChatCompletionBlock)completion {
    
    NSData *data = [self dataForMediaItem:mediaItem];
    NSAssert(data,@"NO Data provided for media");
    
    @weakify(self);
    
    [self.uploadService uploadMediaWithData:data
                                   mimeType:[mediaItem stringMIMEType]
                        withCompletionBlock:^(QBCBlob *blob, NSError *error) {
                            
                            @strongify(self);
                            
                            QBChatAttachment *attachment = [QBChatAttachment new];
                            attachment.type = [mediaItem stringMediaType];
                            attachment.ID = blob.UID;
                            attachment.url = [blob privateUrl];
                            message.attachments = @[attachment];
                            
                            [mediaItem updateWithAttachment:attachment];
                            
                            message.text = [NSString stringWithFormat:@"Attachment %@",[mediaItem stringMediaType]];
                            
                            [self.storeService saveMediaItem:mediaItem];
                            
                            globalUploadCompletionBlock(message.ID, mediaItem, error, self);
                            
                            [chatService sendMessage:message toDialog:dialog saveToHistory:YES saveToStorage:YES completion:completion];
                            
                        } progressBlock:^(float progress) {
                            
                            globalUploadProgressBlock(message.ID, progress, self);
                        }];
    
}

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

- (BOOL)isReadyToPlay:(NSString *)mediaID contentType:(NSString *)contentType {
    
    return [self.storeService isReadyToPlay:mediaID contentType:contentType];
}

//- (NSData *)dataForItem:(QMMediaItem *)item {
//    
//    if (item.data) {
//        return item.data;
//    }
//    if (item.localURL != nil) {
//        NSData *data = [NSData dataWithContentsOfURL:item.localURL];
//        return data;
//    }
//    
//    return nil;
//}


//MARK:-  Global Blocks

void (^globalUploadProgressBlock)(NSString *messageID,float progress, QMMediaService *mediaService) =
^(NSString *messageID, float progress, QMMediaService *mediaService) {
    
    NSMutableArray *handlers = [mediaService.messageUploadHandlers objectForKey:messageID];
    //Inform the handlers
    [handlers enumerateObjectsUsingBlock:^(QMMessageUploadHandler *handler, NSUInteger idx, BOOL *stop) {
        
        if(handler.progressBlock) {
            handler.progressBlock(progress);
        }
        
    }];
};

void (^globalUploadCompletionBlock)(NSString *messageID, QMMediaItem *mediaItem, NSError *error, QMMediaService *mediaService) =
^(NSString *messageID, QMMediaItem *mediaItem, NSError *error, QMMediaService *mediaService)
{
    NSMutableArray *handlers = [mediaService.messageUploadHandlers objectForKey:messageID];
    //Inform the handlers
    [handlers enumerateObjectsUsingBlock:^(QMMessageUploadHandler *handler, NSUInteger idx, BOOL *stop) {
        
        if (handler.completionBlock) {
            handler.completionBlock(mediaItem,error);
        }
    }];
    
    [mediaService.messageUploadHandlers removeObjectForKey:messageID];
};


void (^globalDownloadProgressBlock)(NSString *messageID, NSString *mediaID, float progress, QMMediaService *mediaService) =
^(NSString *messageID, NSString *mediaID, float progress, QMMediaService *mediaService)
{
    
};



void (^globalDownloadCompletionBlock)(NSString *messageID, NSString *mediaID, NSData *mediaData, NSError *error, QMMediaService *mediaService) =
^(NSString *messageID, NSString *mediaID, NSData *mediaData, NSError *error, QMMediaService *mediaService)
{
    NSMutableArray *handlers = [mediaService.messageDownloadHandlers objectForKey:messageID];
    //Inform the handlers
    [handlers enumerateObjectsUsingBlock:^(QMMediaWebHandler *handler, NSUInteger idx, BOOL *stop) {
        
        [handlers enumerateObjectsUsingBlock:^(QMMediaWebHandler *handler, NSUInteger idx, BOOL *stop) {
            
        }];
        
    }];
};

- (void)addUploadingListenerForMessage:(QBChatMessage *)message
                   withCompletionBlock:(void(^)(NSError *))completionBlock
                         progressBlock:(void(^)(float progress))progressBlock {
    
    NSMutableArray *handlers = [self.messageUploadHandlers objectForKey:message.ID];
    
    if (handlers == nil) {
        handlers = [NSMutableArray new];
    }
    
    QMMediaWebHandler *handler = [QMMediaWebHandler downloadingHandlerWithID:message.ID
                                                               progressBlock:progressBlock
                                                             completionBlock:^(NSString *mediaID, NSData *data, NSError *error) {
                                                                 completionBlock(error);
                                                             }];
    
    [handlers addObject:handler];
    [self.messageUploadHandlers setObject:handlers forKey:message.ID];
}


@end
