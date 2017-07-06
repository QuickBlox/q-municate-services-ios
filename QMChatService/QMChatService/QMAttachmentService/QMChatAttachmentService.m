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

const struct QMAttachmentStatusStruct QMAttachmentStatus =
{
    .notLoaded = @"QMAttachmentStatusNotLoaded",
    .loading = @"QMAttachmentStatusLoading",
    .loaded = @"QMAttachmentStatusLoaded",
    .preparing = @"QMAttachmentStatusPreparing",
    .prepared = @"QMAttachmentStatusPrepared",
    .error = @"QMAttachmentStatusPrepared"
};

@interface QMChatAttachmentService() <QMMediaWebServiceDelegate>

@property (nonatomic, strong) NSMutableDictionary *attachmentsStorage;
@property (nonatomic, strong) QBMulticastDelegate <QMChatAttachmentServiceDelegate> *multicastDelegate;
@property (nonatomic, strong) NSMutableDictionary *placeholderAttachments;
@property (nonatomic, strong) NSMutableSet *attachmentsInProgress;
@property (nonatomic, strong) NSMutableDictionary *attachmentsStatuses;
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
        _attachmentsStatuses = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)prepareAttachment:(QBChatAttachment *)attachment messageID:(NSString *)messageID
               completion:(QMMediaInfoServiceCompletionBlock)completion {
    
    __weak typeof(self) weakSelf = self;
    __strong typeof(weakSelf) strongSelf = weakSelf;
   [self.infoService mediaInfoForAttachment:attachment messageID:messageID completion:^(UIImage * _Nullable image, Float64 durationSeconds, CGSize size, NSError * _Nullable error, NSString * _Nonnull messageID, BOOL cancelled) {
       
       if (cancelled) {
           [strongSelf changeAttachmentStatus:QMAttachmentStatus.notLoaded forMessageID:messageID];
       }
            
        if (error) {
            
            [strongSelf changeAttachmentStatus:QMAttachmentStatus.error forMessageID:messageID];
        }
        else {
             [strongSelf changeAttachmentStatus:QMAttachmentStatus.prepared forMessageID:messageID];
        }
   }];
}

- (void)attachmentWithID:(NSString *)attachmentID
                 message:(QBChatMessage *)message
              completion:(void(^)(QBChatAttachment * _Nullable attachment,
                                  NSError * _Nullable error,
                                  QMMessageAttachmentStatus status))completion {
    
    if (attachmentID == nil) {
        
        completion(self.placeholderAttachments[message.ID], nil, QMMessageAttachmentStatusLoading);
        return;
    }
    
    QBChatAttachment *attachment = [self.storeService cachedAttachmentWithID:attachmentID
                                                                forMessageID:message.ID];
    
    if (attachment) {
        //        [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded
        //                                 forMessage:message];
        NSLog(@"_GET CACHED %@ %@", message.ID, attachment.ID);
        completion(attachment, nil, QMMessageAttachmentStatusLoaded);
        return;
    }
    
    attachment = [message.attachments firstObject];
    
    if (attachment.contentType == QMAttachmentContentTypeVideo
        || attachment.contentType == QMAttachmentContentTypeImage) {
        
        [self imageForAttachment:attachment
                         message:message
                      completion:^(UIImage * _Nonnull image,
                                   QMMediaError * _Nonnull error) {
                          QMMessageAttachmentStatus status;
                          if (image) {
                              NSLog(@"_GET IMAGE %@ %@", message.ID, attachment.ID);
                              attachment.image = image;
                              
                              [self.storeService.attachmentsMemoryStorage
                               addAttachment:attachment
                               forMessageID:message.ID];
                              status = QMMessageAttachmentStatusLoaded;
                              //                              [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded
                              //                                                       forMessage:message];
                              [self changeAttachmentStatus:QMAttachmentStatus.loaded forMessageID:message.ID];
                          }
                          else {
                              NSLog(@"_GET ERROR %@ %@", message.ID, attachment.ID);
                              status = QMMessageAttachmentStatusError;
                              if ([error isKindOfClass:[QMMediaError class]]) {
                                  status = error.attachmentStatus;
                              }
                          }
                          
                          completion(attachment, error, status);
                      }];
    }
    
    if (attachment.contentType == QMAttachmentContentTypeAudio) {
        [self audioDataForAttachment:attachment
                             message:message
                          completion:^(NSURL *fileURL, NSError *error) {
                              if (fileURL) {
                                  NSLog(@"_GET FILEURL %@ %@", message.ID, attachment.ID);
                                  attachment.localFileURL = fileURL;
                                  [self.storeService.attachmentsMemoryStorage addAttachment:attachment forMessageID:message.ID];
                                  //                                  [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded
                                  //                                                           forMessage:message];
                                  completion(attachment, nil, QMMessageAttachmentStatusLoaded);
                                  return;
                              }
                              else {
                                  NSLog(@"_GET ERROR %@ %@", message.ID, attachment.ID);
                                  completion(nil, error, QMMessageAttachmentStatusError);
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
    
    [self.infoService cancellOperationWithID:messageID];
    [self.webService cancellOperationWithID:messageID];
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
             NSLog(@"_GET CACHED IMAGE %@ %@", message.ID, attachment.ID);
             if (completion) {
                 completion(image, nil);
             }
         }
         else {
             //             NSLog(@"_GET NOT CACHED IMAGE %@ %@", message.ID, attachment.ID);
             //             if (message.attachmentStatus == QMMessageAttachmentStatusLoading ||
             //                 message.attachmentStatus == QMMessageAttachmentStatusError) {
             //                 NSLog(@"_ALREADY DOWNLOADING %@ %@", message.ID, attachment.ID);
             //                 return;
             //             }
             if ([self statusForMessage:message] == QMAttachmentStatus.loading) {
                 NSLog(@"_ALREADY DOWNLOADING %@ %@", message.ID, attachment.ID);
                 //                 return;
                 return;
             }
             
             QMAttachmentCacheType cacheType = QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc;
             
             if (attachment.contentType == QMAttachmentContentTypeImage) {
                 
                 __strong typeof(weakSelf) strongSelf = weakSelf;
                 
                 [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusLoading
                                                forMessage:message];
                 [strongSelf changeAttachmentStatus:QMAttachmentStatus.loading forMessageID:message.ID];
                 
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
                                                                               dialogID:message.dialogID
                                                                             completion:^{
                                                                                 [strongSelf changeAttachmentStatus:QMAttachmentStatus.loaded forMessageID:message.ID];
                                                                                 completion([UIImage imageWithData:data], nil);
                                                                             }];
                                                  }
                                                  else {
                                                      [strongSelf changeAttachmentStatus:QMAttachmentStatus.error forMessageID:message.ID];
                                                      
                                                      [strongSelf changeMessageAttachmentStatus:error.attachmentStatus
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
                                              } cancellBlock:^(QBChatAttachment *attachment) {
                                                  
                                                  __strong typeof(weakSelf) strongSelf = weakSelf;
                                                  [strongSelf changeAttachmentStatus:QMAttachmentStatus.notLoaded forMessageID:message.ID];
                                                  [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusNotLoaded
                                                                                 forMessage:message];
                                              }];
             }
             else if (attachment.contentType == QMAttachmentContentTypeVideo) {
                 
                 __strong typeof(weakSelf) strongSelf = weakSelf;
                 [strongSelf changeAttachmentStatus:QMAttachmentStatus.loading forMessageID:message.ID];
                 [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusLoading
                                                forMessage:message];
                 
                 [strongSelf.infoService mediaInfoForAttachment:attachment
                                                      messageID:message.ID
                                                     completion:^(UIImage * _Nullable image, Float64 durationSeconds, CGSize size, NSError * _Nullable error, NSString * _Nonnull messageID, BOOL cancelled)
                 {
                                                         if (!error) {
                                                             attachment.duration = durationSeconds;
                                                             attachment.width = size.width;
                                                             attachment.height = size.height;
                                                             
                                                             dispatch_block_t completionBlock = ^{
                                                                 [strongSelf changeAttachmentStatus:QMAttachmentStatus.loaded forMessageID:messageID];
                                                                 [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded
                                                                                                forMessage:message];
                                                             };
                                                             if (image) {
                                                                 [strongSelf.storeService saveData:UIImagePNGRepresentation(image)
                                                                                     forAttachment:attachment
                                                                                         cacheType:cacheType
                                                                                         messageID:message.ID
                                                                                          dialogID:message.dialogID
                                                                                        completion:^{
                                                                                            completionBlock();
                                                                                        }];
                                                                 
                                                             }
                                                             else {
                                                                 [strongSelf.storeService saveAttachment:attachment
                                                                                               cacheType:QMAttachmentCacheTypeMemory
                                                                                               messageID:message.ID
                                                                                                dialogID:message.dialogID
                                                                                              completion:^{
                                                                                                  completionBlock();
                                                                                              }];
                                                             }
                                                             
                                                         }
                                                         else {
                                                             [strongSelf changeAttachmentStatus:QMAttachmentStatus.error forMessageID:messageID];
                                                             [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusError
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
    
    
    if (attachment.contentType == QMAttachmentContentTypeAudio) {
        
        NSURL *fileURL = [self.storeService fileURLForAttachment:attachment
                                                       messageID:message.ID
                                                        dialogID:message.dialogID];
        return fileURL != nil;
    }
    else if (attachment.contentType == QMAttachmentContentTypeVideo) {
        
        return attachment.ID != nil;
    }
    else if (attachment.contentType == QMAttachmentContentTypeImage) {
        return attachment.image != nil;
    }
    return NO;
}

- (QBChatAttachment *)cachedAttachmentWithID:(NSString *)attachmentID
                                forMessageID:(NSString *)messageID {
    
    
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
        NSLog(@"_HAS FILE URL %@ %@", message.ID, attachment.ID);
        completion(localFileURL, nil);
        return;
    }
    else {
        
        if ([self statusForMessage:message] == QMAttachmentStatus.loading) {
            NSLog(@"_ALREADY DOWNLOADING %@ %@", message.ID, attachment.ID);
            return;
        }
        
        __weak typeof(self) weakSelf = self;
        
        [self changeAttachmentStatus:QMAttachmentStatus.loading forMessageID:message.ID];
        [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoading
                                 forMessage:message];
        NSLog(@"_DOWNLOAD %@ %@", message.ID, attachment.ID);
        [self.webService downloadDataForAttachment:attachment
                                         messageID:message.ID
                               withCompletionBlock:^(NSString *attachmentID,
                                                     NSData *data,
                                                     QMMediaError *error)
         {
             __strong typeof(weakSelf) strongSelf = weakSelf;
             
             if (data) {
                 NSLog(@"_HAS DATA %@ %@", message.ID, attachment.ID);
                 [strongSelf.storeService saveData:data
                                     forAttachment:attachment
                                         cacheType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc
                                         messageID:message.ID
                                          dialogID:message.dialogID
                                        completion:^{
                                            NSURL *localFileURL = [self.storeService fileURLForAttachment:attachment
                                                                                                messageID:message.ID
                                                                                                 dialogID:message.dialogID];
                                            if (localFileURL) {
                                                NSLog(@"_HAS localFileURL %@ %@", message.ID, attachment.ID);
                                                [strongSelf changeAttachmentStatus:QMAttachmentStatus.loaded forMessageID:message.ID];
                                                [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded
                                                                               forMessage:message];
                                            }
                                            else {
                                                NSLog(@"_HAS NOT localFileURL %@ %@", message.ID, attachment.ID);
                                                [strongSelf changeAttachmentStatus:QMAttachmentStatus.notLoaded forMessageID:message.ID];
                                                [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusNotLoaded
                                                                               forMessage:message];
                                            }
                                            completion(localFileURL, nil);
                                        }];
             }
             else {
                 if (error.error) {
                     NSLog(@"_HAS ERROR %@ %@", message.ID, attachment.ID);
                     [strongSelf changeAttachmentStatus:QMAttachmentStatus.notLoaded forMessageID:message.ID];
                     [strongSelf changeMessageAttachmentStatus:error.attachmentStatus
                                                    forMessage:message];
                     completion(nil, error.error);
                 }
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
         }
                                      cancellBlock:^(QBChatAttachment *attachment) {
                                          __strong typeof(weakSelf) strongSelf = weakSelf;
                                          [strongSelf changeAttachmentStatus:QMAttachmentStatus.notLoaded forMessageID:message.ID];
                                          [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusNotLoaded
                                                                         forMessage:message];
                                      }];
        
    }
}

- (void)removeAllMediaFiles {
    
    [self.storeService clearCacheForType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc
                              completion:nil];
}

- (void)removeMediaFilesForDialogWithID:(NSString *)dialogID {
    
    [self.storeService clearCacheForDialogWithID:dialogID
                                       cacheType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc
                                      completion:nil];
    
}

- (void)removeMediaFilesForMessagesWithID:(NSArray<NSString *> *)messagesIDs
                                 dialogID:(NSString *)dialogID {
    
    [self.storeService clearCacheForMessagesWithIDs:messagesIDs
                                           dialogID:dialogID
                                          cacheType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc
                                         completion:nil];
}

- (void)removeMediaFilesForMessageWithID:(NSString *)messageID
                                dialogID:(NSString *)dialogID {
    
    [self.storeService clearCacheForMessagesWithIDs:@[messageID]
                                           dialogID:dialogID
                                          cacheType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc
                                         completion:nil];
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
//
- (void)changeMessageAttachmentStatus:(QMMessageAttachmentStatus)status
                           forMessage:(QBChatMessage *)message {
    
    
    return;
}

- (void)changeAttachmentStatus:(NSString *)status
                    forMessageID:(NSString *)messageID {
    
    
    if (self.attachmentsStatuses[messageID] == status) {
        return;
    }
    
    self.attachmentsStatuses[messageID] = status;
    
    if ([self.multicastDelegate respondsToSelector:@selector(chatAttachmentService:
                                                             didChangeAttachmentStatus:
                                                             forMessageID:)]) {
        [self.multicastDelegate chatAttachmentService:self
                            didChangeAttachmentStatus:status
                                           forMessageID:messageID];
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
    
    [self changeAttachmentStatus:QMAttachmentStatus.loading forMessageID:message.ID];
    
    [self changeMessageAttachmentStatus:QMMessageAttachmentStatusLoading
                             forMessage:message];
    
    __weak typeof(self) weakSelf = self;
    
    void(^completionBlock)(NSError *error) = ^(NSError *error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (error) {
            [strongSelf changeAttachmentStatus:QMAttachmentStatus.error forMessageID:message.ID];
            
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
                                       dialogID:dialog.ID
                                     completion:^{
                                         message.attachments = @[attachment];
                                         
                                         [strongSelf changeAttachmentStatus:QMAttachmentStatus.loaded forMessageID:message.ID];
                                         
                                         [strongSelf changeMessageAttachmentStatus:QMMessageAttachmentStatusLoaded
                                                                        forMessage:message];
                                         
                                         
                                         [chatService sendMessage:message
                                                         toDialog:dialog
                                                    saveToHistory:YES
                                                    saveToStorage:YES
                                                       completion:completion];
                                     }];
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
                                 withData:[self.storeService dataForImage:attachment.image]
                      withCompletionBlock:completionBlock
                            progressBlock:progressBlock];
    }
    
}

- (NSString *)statusForMessage:(QBChatMessage *)message {
    
    NSString *status = QMAttachmentStatus.notLoaded;
    
    if (self.attachmentsStatuses[message.ID]!= nil) {
        return self.attachmentsStatuses[message.ID];
    }
    else {
        QBChatAttachment *attachment = [message.attachments firstObject];
        NSURL *fileURl = [self.storeService fileURLForAttachment:attachment messageID:message.ID dialogID:message.dialogID];
        if (fileURl != nil) {
            status = QMAttachmentStatus.loaded;
        }
        else {
            BOOL downloading = [self.webService isDownloadingMessageWithID:message.ID];
            if (downloading) {
                status = QMAttachmentStatus.loading;
            }
        }
        self.attachmentsStatuses[message.ID] = status;
    }
    return status;
}

@end
