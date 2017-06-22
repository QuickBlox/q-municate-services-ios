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

@interface QMChatAttachmentService() <QMMediaWebServiceDelegate>

@property (nonatomic, strong) NSMutableDictionary *attachmentsStorage;
@property (strong, nonatomic) QBMulticastDelegate <QMChatAttachmentServiceDelegate> *multicastDelegate;
@property (strong, nonatomic) NSMutableDictionary *placeholderAttachments;
@property (strong, nonatomic) NSMutableSet *attachmentsInProgress;

@end

@implementation QMChatAttachmentService


- (instancetype)initWithStoreService:(QMMediaStoreService *)storeService
                          webService:(QMMediaWebService *)webService
                         infoService:(QMMediaInfoService *)infoService {
    
    if (self = [super init]) {
        
        _storeService = storeService;
        _webService = webService;
        _infoService = infoService;
        
        _multicastDelegate = (id <QMChatAttachmentServiceDelegate>)[[QBMulticastDelegate alloc] init];
        _attachmentsInProgress = [NSMutableSet set];
        _placeholderAttachments = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)attachmentWithID:(NSString *)attachmentID
                 message:(QBChatMessage *)message
              completion:(void(^)(QBChatAttachment * _Nullable attachment,  NSError * _Nullable error))completion {
    
    if (attachmentID == nil) {
        
        completion(self.placeholderAttachments[message.ID], nil);
        return;
    }
    
    QBChatAttachment *attachment = [self.storeService cachedAttachmentWithID:attachmentID forMessageID:message.ID];
    
    if (attachment) {
        completion(attachment, nil);
        return;
    }
    
    attachment = [message.attachments firstObject];
    
    if (attachment.contentType == QMAttachmentContentTypeVideo
        || attachment.contentType == QMAttachmentContentTypeImage) {
        
        [self imageForAttachment:attachment
                         message:message
                      completion:^(UIImage * _Nonnull image,
                                   QMMediaError * _Nonnull error) {
                          if (image) {
                              
                              attachment.image = image;
                              
                              [self.storeService.attachmentsMemoryStorage
                               addAttachment:attachment
                               forMessageID:message.ID];
                              
                              [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded
                                                       forMessage:message];
                          }
                          else if (error) {
                              [self changeMessageAttachmentStatus:error.attachmentStatus
                                                       forMessage:message];
                          }
                          
                          completion(attachment, error.error);
                      }];
    }
    
    if (attachment.contentType == QMAttachmentContentTypeAudio) {
        [self audioDataForAttachment:attachment
                             message:message
                          completion:^(NSURL *fileURL, NSError *error) {
            if (fileURL) {
                attachment.localFileURL = fileURL;
                [self.storeService.attachmentsMemoryStorage addAttachment:attachment forMessageID:message.ID];
                completion(attachment, nil);
                return;
            }
            else {
                completion(nil, error);
                return;
            }
            
        }];
    }
}

- (QBChatAttachment *)placeholderAttachment:(NSString *)messageID {
    
    return _placeholderAttachments[messageID];
}

- (void)cancelOperationsForAttachment:(QBChatAttachment *)attachment
                            messageID:(NSString *)messageID {
    
    [self.infoService cancelInfoOperationForKey:attachment.ID];
    [self.webService cancelDownloadOperationForAttachment:attachment];
}

- (void)imageForAttachmentMessage:(QBChatMessage *)attachmentMessage
                       completion:(void(^)(NSError *error, UIImage *image))completion {
    
    QBChatAttachment *attachment = [attachmentMessage.attachments firstObject];
    [self imageForAttachment:attachment
                     message:attachmentMessage
                  completion:^(UIImage * _Nonnull image, QMMediaError * _Nonnull error) {
                      if (completion) {
                          completion(error.error, image);
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
                completion:(void(^)(UIImage *image,
                                    QMMediaError *error))completion {
    
    __weak typeof(self) weakSelf = self;
    
    [self.storeService cachedImageForAttachment:attachment
                                      messageID:message.ID
                                       dialogID:message.dialogID
                                     completion:^(UIImage *image)
     {
         if (image) {
             if (completion) {
                 completion(image, nil);
             }
         }
         else {
             
             if (message.attachmentStatus == QMMessageAttachmentStatusLoading ||
                 message.attachmentStatus == QMMessageAttachmentStatusError) {
                 return;
             }
             
             QMAttachmentCacheType cacheType = QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc;
             
             if (attachment.contentType == QMAttachmentContentTypeImage) {
                 
                 [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoading
                                          forMessage:message];
                 
                 __strong typeof(weakSelf) strongSelf = weakSelf;
                 [strongSelf.webService downloadDataForAttachment:attachment
                                                        messageID:message.ID
                                              withCompletionBlock:^(NSString *attachmentID,
                                                                    NSData *data,
                                                                    QMMediaError *error) {
                                                  if (data) {
                                                      [strongSelf.storeService saveData:data
                                                                          forAttachment:attachment
                                                                              cacheType:cacheType
                                                                              messageID:message.ID
                                                                               dialogID:message.dialogID];
                                                      
                                                      [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded
                                                                               forMessage:message];
                                                      completion([UIImage imageWithData:data], nil);
                                                  }
                                                  else {
                                                      [self changeMessageAttachmentStatus:error.attachmentStatus
                                                                               forMessage:message];
                                                      completion(nil, error);
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
                 
                 __strong typeof(weakSelf) strongSelf = weakSelf;
                 
                 [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoading
                                          forMessage:message];
                 
                 [strongSelf.infoService videoThumbnailForAttachment:attachment
                                                          completion:^(UIImage *image, NSError *error)
                  {
                      if (image) {
                          [strongSelf.storeService saveData:UIImagePNGRepresentation(image)
                                              forAttachment:attachment
                                                  cacheType:cacheType
                                                  messageID:message.ID
                                                   dialogID:message.dialogID];
                          [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded
                                                   forMessage:message];
                          
                      }
                      else {
                          [self changeMessageAttachmentStatus:QMMessageAttachmentStatusError
                                                   forMessage:message];
                      }
                      
                      completion(image, error);
                      
                  }];
             }
         }
     }];
}

- (BOOL)attachmentIsReadyToPlay:(QBChatAttachment *)attachment
                        message:(QBChatMessage *)message {
    
    if ([_attachmentsInProgress containsObject:attachment.ID]) {
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
    else if (attachment.contentType == QMAttachmentContentTypeImage) {
        return attachment.image != nil;
    }
    return NO;
}

- (QBChatAttachment *)cachedAttachmentWithID:(NSString *)attachmentID
                                forMessageID:(NSString *)messageID {
    
    if ([self.attachmentsInProgress containsObject:attachmentID]) {
        return  nil;
    }
    
    return [self.storeService cachedAttachmentWithID:attachmentID
                                        forMessageID:messageID];
}

- (void)audioDataForAttachment:(QBChatAttachment *)attachment
                       message:(QBChatMessage *)message
                    completion:(void(^)(NSURL *fileURL, NSError *error))completion {
    
    
    NSURL *localFileURL = [self.storeService fileURLForAttachment:attachment
                                                        messageID:message.ID
                                                         dialogID:message.dialogID];
    if (localFileURL) {
        completion(localFileURL, nil);
        return;
    }
    else {
        __weak typeof(self) weakSelf = self;
        
        [self.webService downloadDataForAttachment:attachment
                                         messageID:message.ID
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
                 completion(localFileURL, nil);
             }
             else {
                 if (error.error)
                     [strongSelf changeMessageAttachmentStatus:error.attachmentStatus
                                                    forMessage:message];
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
}

- (void)removeAllMediaFiles {
    
    [self.storeService clearCacheForType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc];
}

- (void)removeMediaFilesForDialogWithID:(NSString *)dialogID {
    
    [self.storeService clearCacheForDialogWithID:dialogID
                                       cacheType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc];
    
}

- (void)removeMediaFilesForMessagesWithID:(NSArray<NSString *> *)messagesIDs
                                 dialogID:(NSString *)dialogID {
    
    [self.storeService clearCacheForMessagesWithIDs:messagesIDs
                                           dialogID:dialogID
                                          cacheType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc];
}

- (void)removeMediaFilesForMessageWithID:(NSString *)messageID
                                dialogID:(NSString *)dialogID {
    
    [self.storeService clearCacheForMessagesWithIDs:@[messageID]
                                           dialogID:dialogID
                                          cacheType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc];
}

- (void)statusForAttachment:(QBChatAttachment *)attachment
                 completion:(void(^)(int))completionBlock {
    
}

//MARK:- Add / Remove Multicast delegate

- (void)addDelegate:(id <QMChatAttachmentServiceDelegate>)delegate {
    
    [self.multicastDelegate addDelegate:delegate];
}

- (void)removeDelegate:(id <QMChatAttachmentServiceDelegate>)delegate {
    
    [self.multicastDelegate removeDelegate:delegate];
}

- (void)changeMessageAttachmentStatus:(QMMessageAttachmentStatus)status
                           forMessage:(QBChatMessage *)message {
    
    message.attachmentStatus = status;
     dispatch_async(dispatch_get_main_queue(), ^{
    if ([self.multicastDelegate respondsToSelector:@selector(chatAttachmentService:
                                                             didChangeAttachmentStatus:
                                                             forMessage:)]) {
        [self.multicastDelegate chatAttachmentService:self
                            didChangeAttachmentStatus:status
                                           forMessage:message];
    }
 });
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
                                messageID:message.ID
                              withFileURL:attachment.localFileURL
                      withCompletionBlock:completionBlock
                            progressBlock:progressBlock];
    }
    
    else if (attachment.contentType == QMAttachmentContentTypeImage) {
        
        [self.webService uploadAttachment:attachment
                                messageID:message.ID
                                 withData:UIImagePNGRepresentation(attachment.image)
                      withCompletionBlock:completionBlock
                            progressBlock:progressBlock];
    }
    
}

@end
