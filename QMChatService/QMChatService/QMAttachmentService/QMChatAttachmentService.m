//
//  QMChatAttachmentService.m
//  QMServices
//
//  Created by Injoit on 7/1/15.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//

#import "QMChatAttachmentService.h"

#import "QMChatService.h"
#import "QMMediaBlocks.h"
#import "QMMediaError.h"

#import "QBChatMessage+QMCustomParameters.h"

#import "QBChatAttachment+QMCustomParameters.h"
#import "QBChatAttachment+QMFactory.h"

#import "QMSLog.h"

#import "QMMediaStoreService.h"
#import "QMMediaWebService.h"
#import "QMMediaInfoService.h"

@interface QMChatAttachmentService() <QMMediaStoreServiceDelegate>

@property (nonatomic, strong) NSMutableDictionary *attachmentsStorage;
@property (strong, nonatomic) QBMulticastDelegate <QMChatAttachmentServiceDelegate> *multicastDelegate;
@property (strong, nonatomic) NSMutableDictionary *placeholderAttachments;
@property (strong, nonatomic) NSMutableArray *mediaItemsInProgress;

@end

@implementation QMChatAttachmentService

- (instancetype)init {
    
    if (self = [super init]) {
        
        _multicastDelegate = (id <QMChatAttachmentServiceDelegate>)[[QBMulticastDelegate alloc] init];
        _attachmentsStorage = [NSMutableDictionary dictionary];
        _mediaItemsInProgress = [NSMutableArray array];
        _placeholderAttachments = [NSMutableDictionary dictionary];
    }
    
    return self;
}


- (QBChatAttachment *)placeholderAttachment:(NSString *)messageID {
    
    return _placeholderAttachments[messageID];
}

- (void)cancelOperationsForAttachment:(QBChatAttachment *)attachment {
    
    [self.infoService cancelInfoOperationForKey:attachment.ID];
    [self.webService cancelDownloadOperationForAttachment:attachment];
}

- (void)imageForAttachmentMessage:(QBChatMessage *)attachmentMessage
                       completion:(void(^)(NSError *error, UIImage *image))completion {
    
    QBChatAttachment *attachment = [attachmentMessage.attachments firstObject];
    [self imageForAttachment:attachment message:attachmentMessage completion:^(UIImage * _Nonnull image, NSError * _Nonnull error) {
        if (completion) {
            completion(error, image);
        }
    }];
}

- (void)localImageForAttachmentMessage:(QBChatMessage *)attachmentMessage
                            completion:(void(^)(NSError *error, UIImage *image))completion {
    
    QBChatAttachment *attachment = [attachmentMessage.attachments firstObject];
    [self.storeService cachedImageForAttachment:attachment
                                      messageID:attachmentMessage.ID
                                       dialogID:attachmentMessage.dialogID
                                     completion:^(UIImage *image){
                                         if (completion) {
                                             completion(nil, image);
                                         }
                                     }];
}

- (void)imageForAttachment:(QBChatAttachment *)attachment
                   message:(QBChatMessage *)message
                completion:(void(^)(UIImage *image, NSError *error))completion {
    
    __weak typeof(self) weakSelf = self;
    
    [self.storeService cachedImageForAttachment:attachment
                                      messageID:message.ID
                                       dialogID:message.dialogID
                                     completion:^(UIImage *image)
     {
         
         if (!image) {
             
             if (attachment.status == QMAttachmentStatusLoading ||
                 attachment.status == QMAttachmentStatusError) {
                 return;
             }
             
             QMAttachmentCacheType cacheType = QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc;
             
             if (attachment.contentType == QMAttachmentContentTypeImage) {
                 
                 attachment.status = QMAttachmentStatusLoading;
                 __strong typeof(weakSelf) strongSelf = weakSelf;
                 [strongSelf.webService downloadDataForAttachment:attachment
                                              withCompletionBlock:^(NSString *attachmentID,
                                                                    NSData *data,
                                                                    QMMediaError *error) {
                                                  if (data) {
                                                      [strongSelf.storeService saveData:data
                                                                          forAttachment:attachment
                                                                              cacheType:cacheType
                                                                              messageID:message.ID
                                                                               dialogID:message.dialogID];
                                                      attachment.status = QMAttachmentStatusLoaded;
                                                      completion([UIImage imageWithData:data], nil);
                                                  }
                                                  else {
                                                      attachment.status = QMAttachmentStatusError;
                                                      completion(nil, error.error);
                                                  }
                                              } progressBlock:^(float progress) {
                                                  
                                                  __strong typeof(weakSelf) strongSelf = weakSelf;
                                                  if ([strongSelf.multicastDelegate respondsToSelector:@selector(chatAttachmentService:
                                                                                                                 didChangeLoadingProgress:
                                                                                                                 forMessage:
                                                                                                                 attachment:)]) {
                                                      [strongSelf.multicastDelegate chatAttachmentService:self
                                                                                 didChangeLoadingProgress:progress
                                                                                               forMessage:message
                                                                                               attachment:attachment];
                                                  }
                                              }];
             }
             else if (attachment.contentType == QMAttachmentContentTypeVideo) {
                 
                 if (attachment.status == QMAttachmentStatusPreparing ||
                     attachment.status == QMAttachmentStatusError) {
                     return;
                 }
                 __strong typeof(weakSelf) strongSelf = weakSelf;
                 
                 attachment.status = QMAttachmentStatusPreparing;
                 [strongSelf.infoService videoThumbnailForAttachment:attachment
                                                          completion:^(UIImage *image, NSError *error)
                  {
                      if (image) {
                          [strongSelf.storeService saveData:UIImagePNGRepresentation(image)
                                              forAttachment:attachment
                                                  cacheType:cacheType
                                                  messageID:message.ID
                                                   dialogID:message.dialogID];
                          attachment.status = QMAttachmentStatusPrepared;
                      }
                      else {
                          attachment.status = QMAttachmentStatusError;
                      }
                      
                      completion(image, error);
                      
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

- (BOOL)attachmentIsReadyToPlay:(QBChatAttachment *)attachment
                        message:(QBChatMessage *)message {
    
    if ([_mediaItemsInProgress containsObject:attachment.ID]) {
        return  NO;
    }
    
    if (attachment.contentType == QMAttachmentContentTypeAudio) {
        
        NSURL *fileURL = [self.storeService fileURLForAttachment:attachment
                                                       messageID:message.ID
                                                        dialogID:message.dialogID];
        return fileURL != nil;
    }
    else if (attachment.contentType == QMAttachmentContentTypeVideo) {
        
        return YES;
    }
    return NO;
}

- (QBChatAttachment *)cachedAttachmentWithID:(NSString *)attachmentID
                                forMessageID:(NSString *)messageID {
    
    if ([self.mediaItemsInProgress containsObject:attachmentID]) {
        return  nil;
    }
    
    return [self.storeService cachedAttachmentWithID:attachmentID
                                        forMessageID:messageID];
}

- (void)audioDataForAttachment:(QBChatAttachment *)attachment
                       message:(QBChatMessage *)message
                    completion:(void(^)(BOOL isReady, NSError *error))completion {
    
    if ([self cachedAttachmentWithID:attachment.ID
                        forMessageID:message.ID]) {
        
        completion(YES, nil);
        return;
    }
    
    NSURL *localFileURL = [self.storeService fileURLForAttachment:attachment
                                                        messageID:message.ID
                                                         dialogID:message.dialogID];
    if (localFileURL) {
        attachment.localFileURL = localFileURL;
        completion(YES, nil);
        return;
    }
    else {
        __weak typeof(self) weakSelf = self;
        
        [self.webService downloadDataForAttachment:attachment
                               withCompletionBlock:^(NSString *attachmentID,
                                                     NSData *data,
                                                     QMMediaError *error)
         {
             __strong typeof(weakSelf) strongSelf = weakSelf;
             
             if (data) {
                 [strongSelf.storeService saveData:data
                                     forAttachment:attachment
                                         cacheType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc
                                         messageID:message.ID
                                          dialogID:message.dialogID];
                 
                 [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded
                                                forMessage:message];
                 completion(YES, nil);
             }
             else {
                 [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusError
                                                forMessage:message];
                 completion(NO, error.error);
             }
         } progressBlock:^(float progress) {
             
             __strong typeof(weakSelf) strongSelf = weakSelf;
             if ([strongSelf.multicastDelegate respondsToSelector:@selector(chatAttachmentService:
                                                                            didChangeLoadingProgress:
                                                                            forMessage:
                                                                            attachment:)]) {
                 [strongSelf.multicastDelegate chatAttachmentService:self
                                            didChangeLoadingProgress:progress
                                                          forMessage:message
                                                          attachment:attachment];
             }
         }];
        
    }
}

- (void)removeAllMediaFiles {
    
    [self.storeService clearCacheForType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc];
}

- (void)removeMediaFilesForDialogWithID:(NSString *)dialogID {
    
    [self.storeService clearCacheForDialogWithID:dialogID
                                       cacheType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc];
    
}

- (void)removeMediaFilesForMessageWithID:(NSString *)messageID
                                dialogID:(NSString *)dialogID {
    
    [self.storeService clearCacheForMessageWithID:messageID
                                         dialogID:dialogID
                                        cacheType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc];
}

- (void)statusForAttachment:(QBChatAttachment *)attachment
                 completion:(void(^)(int))completionBlock {
    
}

- (void)didRemoveAttachment:(nonnull QBChatAttachment *)attachment messageID:(nonnull NSString *)messageID dialogID:(nonnull NSString *)dialogID {
    
}

- (void)didUpdateAttachment:(nonnull QBChatAttachment *)attachment messageID:(nonnull NSString *)messageID dialogID:(nonnull NSString *)dialogID {
    
}




//MARK:- Add / Remove Multicast delegate

- (void)addDelegate:(id <QMChatAttachmentServiceDelegate>)delegate {
    
    [self.multicastDelegate addDelegate:delegate];
}

- (void)removeDelegate:(id <QMChatAttachmentServiceDelegate>)delegate {
    
    [self.multicastDelegate removeDelegate:delegate];
}



- (void)changeMessageAttachmentStatus:(QMMessageAttachmentStatus)status forMessage:(QBChatMessage *)message {
    
    if (message.attachmentStatus != status) {
        message.attachmentStatus = status;
        
        if ([self.multicastDelegate respondsToSelector:@selector(chatAttachmentService:didChangeAttachmentStatus:forMessage:)]) {
            [self.multicastDelegate chatAttachmentService:self didChangeAttachmentStatus:status forMessage:message];
        }
    }
    
}

- (void)uploadAndSendAttachmentMessage:(QBChatMessage *)message
                              toDialog:(QBChatDialog *)dialog
                       withChatService:(QMChatService *)chatService
                     withAttachedImage:(UIImage *)image
                            completion:(QBChatCompletionBlock)completion {
    
    QBChatAttachment *atatchment = [QBChatAttachment imageAttachmentWithImage:image];
    [self uploadAndSendAttachmentMessage:message
                                toDialog:dialog
                         withChatService:chatService
                              attachment:atatchment
                              completion:completion];
    
}
- (void)uploadAndSendAttachmentMessage:(QBChatMessage *)message
                              toDialog:(QBChatDialog *)dialog
                       withChatService:(QMChatService *)chatService
                            attachment:(QBChatAttachment *)attachment
                            completion:(QBChatCompletionBlock)completion {
    
    message.attachments = @[attachment];
    
    _placeholderAttachments[message.ID] = attachment;
    
    [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoading
                             forMessage:message];
    
    __weak typeof(self) weakSelf = self;
    
    void(^completionBlock)(NSError *error) = ^(NSError *error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (error) {
            
            [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusError
                                           forMessage:message];
            
            completion(error);
            return;
        }
        
        message.text =
        [NSString stringWithFormat:@"%@ attachment",
         [[attachment stringContentType] capitalizedString]];
        
        [strongSelf.storeService saveAttachment:attachment
                                      cacheType:QMAttachmentCacheTypeDisc|QMAttachmentCacheTypeMemory
                                      messageID:message.ID
                                       dialogID:dialog.ID];
        
        message.attachments = @[attachment];
        
        [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded
                                       forMessage:message];
        
        
        
        [chatService sendMessage:message
                        toDialog:dialog
                   saveToHistory:YES
                   saveToStorage:YES
                      completion:completion];
    };
    
    void(^progressBlock)(float progress) = ^(float progress) {
        
        if ([self.multicastDelegate respondsToSelector:@selector(chatAttachmentService:
                                                                 didChangeUploadingProgress:
                                                                 forMessage:)]) {
            [self.multicastDelegate chatAttachmentService:self
                               didChangeUploadingProgress:progress
                                               forMessage:message];
        }
    };
    
    if (attachment.localFileURL) {
        
        [self.webService uploadAttachment:attachment
                              withFileURL:attachment.localFileURL
                      withCompletionBlock:completionBlock
                            progressBlock:progressBlock];
    }
    
    else if (attachment.contentType == QMAttachmentContentTypeImage) {
        
        [self.webService uploadAttachment:attachment
                                 withData:UIImagePNGRepresentation(attachment.image)
                      withCompletionBlock:completionBlock
                            progressBlock:progressBlock];
    }
    
}

@end
