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
#import "QBChatMessage+QMCustomParameters.h"

#import "QBChatAttachment+QMCustomParameters.h"
#import "QBChatAttachment+QMFactory.h"

#import "QMSLog.h"

const struct QMAttachmentStatusStruct QMAttachmentStatus =
{
    .notLoaded = @"QMAttachmentStatusNotLoaded",
    .downloading = @"QMAttachmentStatusDownloading",
    .uploading = @"QMAttachmentStatusUploadingloading",
    .loaded = @"QMAttachmentStatusLoaded",
    .preparing = @"QMAttachmentStatusPreparing",
    .prepared = @"QMAttachmentStatusPrepared",
    .error = @"QMAttachmentStatusError"
};



@implementation QMAttachmentOperation

- (void)setCancelBlock:(dispatch_block_t)cancelBlock {
    // check if the operation is already cancelled, then we just call the cancelBlock
    if (self.isCancelled) {
        if (cancelBlock) {
            cancelBlock();
        }
        _cancelBlock = nil; // don't forget to nil the cancelBlock, otherwise we will get crashes
    } else {
        _cancelBlock = [cancelBlock copy];
    }
}

- (void)dealloc {
    NSLog(@"deallock");
}

- (void)cancel {
    
    [super cancel];
    
    [_storeOperation cancel];
    _storeOperation = nil;
    
    [_mediaInfoOperation cancel];
    _mediaInfoOperation = nil;
    [_uploadOperation cancel];
    _uploadOperation = nil;
    
    if (self.cancelBlock) {
        self.cancelBlock();
        
        _cancelBlock = nil;
    }
}

@end

@interface QMChatAttachmentService() <QMMediaWebServiceDelegate>

@property (nonatomic, strong) NSMutableDictionary *attachmentsStorage;
@property (nonatomic, strong) QBMulticastDelegate <QMChatAttachmentServiceDelegate> *multicastDelegate;
@property (nonatomic, strong) NSMutableDictionary *placeholderAttachments;
@property (nonatomic, strong) NSMutableSet *attachmentsInProgress;
@property (nonatomic, strong) NSMutableDictionary *attachmentsStatuses;
@property (nonatomic, strong) NSMutableDictionary *runningOperations;
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
        _runningOperations = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)prepareAttachment:(QBChatAttachment *)attachment
                messageID:(NSString *)messageID
               completion:(QMMediaInfoServiceCompletionBlock)completion {
    
    __weak typeof(self) weakSelf = self;
    
    [self changeAttachmentStatus:QMAttachmentStatus.preparing forMessageID:messageID];
    
    [self.infoService mediaInfoForAttachment:attachment
                                   messageID:messageID
                                  completion:^(UIImage * _Nullable image,
                                               Float64 durationSeconds,
                                               CGSize size,
                                               NSError * _Nullable error,
                                               NSString * _Nonnull messageID,
                                               BOOL cancelled)
     {
         
         dispatch_async(dispatch_get_main_queue(), ^{
             __strong typeof(weakSelf) strongSelf = weakSelf;
             if (cancelled) {
                 [strongSelf changeAttachmentStatus:QMAttachmentStatus.notLoaded forMessageID:messageID];
                 return;
             }
             
             if (error) {
                 [strongSelf changeAttachmentStatus:QMAttachmentStatus.error forMessageID:messageID];
             }
             else {
                 
                 [strongSelf changeAttachmentStatus:QMAttachmentStatus.prepared forMessageID:messageID];
             }
             if (completion) {
                 completion(image, durationSeconds, size,error,messageID,cancelled);
             }
         });
     }];
}

- (QBChatAttachment *)placeholderAttachment:(NSString *)messageID {
    
    return _placeholderAttachments[messageID];
}

- (void)cancelOperationsForAttachment:(QBChatAttachment *)attachment
                            messageID:(NSString *)messageID {
    NSLog(@"CALL CANCELL ID: %@", messageID);
    QMAttachmentOperation *operation = nil;
    @synchronized (self.runningOperations) {
        operation = self.runningOperations [messageID];
    }
    if (!operation) {
        NSLog(@"NO OPERATION FOR CALL CANCELL ID: %@", messageID);
    }
    [operation cancel];
    
}

- (void)imageForAttachmentMessage:(QBChatMessage *)attachmentMessage
                       completion:(void(^)(NSError *error, UIImage *image))completion {
    
    QBChatAttachment *attachment = [attachmentMessage.attachments firstObject];
    [self imageForAttachment:attachment
                     message:attachmentMessage
                  completion:^(UIImage * _Nonnull image, NSError * _Nonnull error) {
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
                completion:(void(^)(UIImage *image,
                                    NSError *error))imageCompletionBlock {
    /*
     __weak typeof(self) weakSelf = self;
     
     [self.storeService cachedImageForAttachment:attachment
     messageID:message.ID
     dialogID:message.dialogID
     completion:^(UIImage *image)
     {
     if (image) {
     NSLog(@"_GET CACHED IMAGE %@ %@", message.ID, attachment.ID);
     if (imageCompletionBlock) {
     imageCompletionBlock(image, nil);
     }
     }
     else {
     
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
     
     [strongSelf.webService downloadMessage:message attachmentID:attachment.ID
     progressBlock:^(float progress)
     {
     __strong typeof(weakSelf) strongSelf = weakSelf;
     if ([strongSelf.multicastDelegate respondsToSelector:@selector(chatAttachmentService:
     didChangeLoadingProgress:
     forMessage:
     attachment:)]) {
     [strongSelf.multicastDelegate chatAttachmentService:self
     didChangeLoadingProgress:progress
     forMessage:message
     attachment:attachment];
     }  completionBlock:^(QMDownloadOperation * _Nonnull downloadOperation)
     {
     if (downloadOperation.isCancelled) {
     [strongSelf changeAttachmentStatus:QMAttachmentStatus.notLoaded forMessageID:message.ID];
     return;
     }
     
     
     if (downloadOperation.data) {
     [strongSelf.storeService saveData:downloadOperation.data
     forAttachment:attachment
     cacheType:cacheType
     messageID:message.ID
     dialogID:message.dialogID
     completion:^{
     [strongSelf changeAttachmentStatus:QMAttachmentStatus.loaded forMessageID:message.ID];
     imageCompletionBlock([UIImage imageWithData:downloadOperation.data], nil);
     }];
     }
     else {
     
     [strongSelf changeAttachmentStatus:QMAttachmentStatus.notLoaded forMessageID:message.ID];
     
     imageCompletionBlock(nil, downloadOperation.error);
     }
     
     }];
     
     }
     */
    /*
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
     }];*/
    
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


- (void)removeAllMediaFiles {
    
    [self.storeService clearCacheForType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc
                              completion:nil];
    [self.attachmentsStatuses removeAllObjects];
}

- (void)removeMediaFilesForDialogWithID:(NSString *)dialogID {
    
    [self.storeService clearCacheForDialogWithID:dialogID
                                       cacheType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc
                                      completion:nil];
    
}

- (void)removeMediaFilesForMessagesWithID:(NSArray<NSString *> *)messagesIDs
                                 dialogID:(NSString *)dialogID {
    for (NSString *messageID in messagesIDs) {
        self.attachmentsStatuses[messageID] = nil;
    }
    [self.storeService clearCacheForMessagesWithIDs:messagesIDs
                                           dialogID:dialogID
                                          cacheType:QMAttachmentCacheTypeMemory|QMAttachmentCacheTypeDisc
                                         completion:nil];
}

- (void)removeMediaFilesForMessageWithID:(NSString *)messageID
                                dialogID:(NSString *)dialogID {
    
    self.attachmentsStatuses[messageID] = nil;
    
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
    NSLog(@"_UPLOAD and send call %@",message.ID);
    [chatService.deferredQueueManager addOrUpdateMessage:message];
    
    [self uploadAttachmentMessage:message
                         toDialog:dialog
                       attachment:attachment
                       completion:^(NSError *error) {
                           
                           if (!error) {
                               NSLog(@"_UPLOAD NO ERROR completion %@",message.ID);
                               [chatService sendMessage:message
                                               toDialog:dialog
                                          saveToHistory:YES
                                          saveToStorage:YES
                                             completion:completion];
                           }
                           else {
                               NSLog(@"_UPLOAD has error completion %@",message.ID);
                               [chatService.deferredQueueManager addOrUpdateMessage:message];
                               completion(error);
                           }
                       }];
}

- (void)uploadAttachmentMessage:(QBChatMessage *)message
                       toDialog:(QBChatDialog *)dialog
                     attachment:(QBChatAttachment *)attachment
                     completion:(void(^)(NSError *))completion {
    
    BOOL hasOperation = NO;
    @synchronized (self.runningOperations) {
        hasOperation = self.runningOperations[message.ID] != nil;
    }
    
    if (hasOperation) {
        NSLog(@"_UPLOAD 0hasOperation completion %@",message.ID);
        return;
    }
    
    message.attachments = @[attachment];
    
    _placeholderAttachments[message.ID] = attachment;
    
    void(^progressBlock)(float progress) = ^(float progress) {
        
        if ([self.multicastDelegate respondsToSelector:@selector(chatAttachmentService:
                                                                 didChangeUploadingProgress:
                                                                 forMessage:)]) {
            [self.multicastDelegate chatAttachmentService:self
                               didChangeUploadingProgress:progress
                                               forMessage:message];
        }
    };
    
    
    QMAttachmentOperation *attachmentOperation = [QMAttachmentOperation new];
    attachmentOperation.identifier = message.ID;
    
    @synchronized (self.runningOperations) {
        self.runningOperations[message.ID] = attachmentOperation;
    }
    
    __weak QMAttachmentOperation *weakOperation = attachmentOperation;
    
    // Create the dispatch group
    dispatch_group_t uploadGroup = dispatch_group_create();
    
    if (!attachment.isPrepared) {
        
        [self.infoService mediaInfoForAttachment:attachment
                                       messageID:message.ID
                                      completion:^(UIImage * _Nullable image,
                                                   Float64 durationInSeconds,
                                                   CGSize size,
                                                   NSError * _Nullable error,
                                                   NSString * _Nonnull messageID,
                                                   BOOL cancelled) {
            if (!cancelled) {
                if (!error) {
                attachment.image = image;
                attachment.duration = durationInSeconds;
                attachment.width = size.width;
                attachment.height = size.height;
                }
                
            }
              dispatch_group_leave(uploadGroup);
        }];
    }
    
    dispatch_group_wait(uploadGroup,DISPATCH_TIME_FOREVER);
    
    NSOperation *storeOperation = [self.storeService cachedAttachment:attachment
                                                            messageID:message.ID
                                                             dialogID:message.dialogID
                                                           completion:^(NSURL * _Nonnull fileURL, NSData * _Nonnull data)
                                   {
                                       NSLog(@"_UPLOAD 1 STORE SERVICE completion %@",message.ID);
                                       __strong __typeof(weakOperation) strongOperation = weakOperation;
                                       if (attachmentOperation.isCancelled) {
                                           NSLog(@"_UPLOAD 2 is Cancelled %@",message.ID);
                                           
                                           [self safelyRemoveOperationFromRunning:strongOperation];
                                           return;
                                       }
                                       if (fileURL) {
                                           NSLog(@"_UPLOAD 3 has file URL %@",message.ID);
                                           [self changeAttachmentStatus:QMAttachmentStatus.loaded forMessageID:message.ID];
                                           attachment.localFileURL = fileURL;
                                           completion(nil);
                                           [self safelyRemoveOperationFromRunning:strongOperation];
                                       }
                                       else {
                                           if ([self statusForMessage:message] == QMAttachmentStatus.uploading) {
                                               NSLog(@"_UPLOAD 4 STATUS IS LOADING ID ID: %@", message.ID);
                                               return;
                                           }
                                           
                                           [self changeAttachmentStatus:QMAttachmentStatus.uploading forMessageID:message.ID];
                                           
                                           
                                           void(^operationCompletionBlock)(QMUploadOperation *operation) = ^(QMUploadOperation *operation)
                                           {
                                               NSError * error = operation.error;
                                               __strong __typeof(weakOperation) strongOperation = weakOperation;
                                               NSLog(@"_UPLOAD 5 completion upload: %@", message.ID);
                                               if (!strongOperation || strongOperation.isCancelled) {
                                                   NSLog(@"_UPLOAD 6 is cancelled: %@", message.ID);
                                                   [self safelyRemoveOperationFromRunning:strongOperation];
                                                   [self changeAttachmentStatus:QMAttachmentStatus.notLoaded forMessageID:message.ID];
                                                   return;
                                               }
                                               else if (error) {
                                                   NSLog(@"_UPLOAD 6 error: %@", message.ID);
                                                   [self changeAttachmentStatus:QMAttachmentStatus.notLoaded forMessageID:message.ID];
                                                   [self safelyRemoveOperationFromRunning:strongOperation];
                                                   completion(error);
                                               }
                                               else {
                                                   
                                                   [self.storeService saveAttachment:attachment
                                                                           cacheType:QMAttachmentCacheTypeDisc|QMAttachmentCacheTypeMemory messageID:message.ID
                                                                            dialogID:message.dialogID
                                                                          completion:^{
                                                                              NSLog(@"_UPLOAD 7 save to storage: %@", message.ID);
                                                                              if (strongOperation && !strongOperation.isCancelled) {
                                                                                  NSLog(@"_UPLOAD 8 change status: %@", message.ID);
                                                                                  [self changeAttachmentStatus:QMAttachmentStatus.loaded forMessageID:message.ID];
                                                                                  
                                                                                  completion(nil);
                                                                                  [self safelyRemoveOperationFromRunning:strongOperation];
                                                                              }
                                                                              else {
                                                                                  [self safelyRemoveOperationFromRunning:strongOperation];
                                                                                  NSLog(@"_UPLOAD 8 Cancelled: %@", message.ID);
                                                                              }
                                                                          }];
                                                   
                                               }
                                               
                                           };
                                           
                                           if (attachment.contentType == QMAttachmentContentTypeImage) {
                                               NSData *imageData = [self.storeService dataForImage:attachment.image];
                                               [self.webService uploadAttachment:attachment messageID:message.ID withData:imageData progressBlock:progressBlock completionBlock:operationCompletionBlock];
                                           }
                                           else {
                                               [self.webService uploadAttachment:attachment messageID:message.ID withFileURL:attachment.localFileURL progressBlock:progressBlock completionBlock:operationCompletionBlock];
                                           }
                                       }
                                   }];
    
    attachmentOperation.storeOperation = storeOperation;
    
    attachmentOperation.cancelBlock = ^{
        
        __strong __typeof(weakOperation) strongOperation = weakOperation;
        //       cancelBlock();
        [self safelyRemoveOperationFromRunning:strongOperation];
    };
}

- (void)attachmentWithID:(NSString *)attachmentID
                 message:(QBChatMessage *)message
           progressBlock:(QMMediaProgressBlock)progressBlock
              completion:(void(^)(QMAttachmentOperation *))completionBlock {
    
    QMAttachmentOperation *attachmentOperation =  [QMAttachmentOperation new];
    
    QBChatAttachment *cachedAttachment = [self.storeService.attachmentsMemoryStorage
                                          attachmentWithID:attachmentID
                                          fromMessageID:message.ID];
    if (cachedAttachment) {
        attachmentOperation.attachment = cachedAttachment;
        completionBlock(attachmentOperation);
    }
    else {
        
        QMAttachmentOperation *attachmentOperation =  [QMAttachmentOperation new];
        attachmentOperation.identifier = message.ID;
        NSLog(@"CREATE ATTACHMENT OPERAION WITH ID ID: %@", attachmentOperation.identifier);
        @synchronized (self.runningOperations) {
            self.runningOperations[message.ID] = attachmentOperation;
        }
        
        QBChatAttachment *attachment = message.attachments.firstObject;
        NSParameterAssert(attachment != nil);
        __weak QMAttachmentOperation *weakOperation = attachmentOperation;
        
        if (attachment.contentType == QMAttachmentContentTypeAudio) {
            
            if ([self statusForMessage:message] == QMAttachmentStatus.downloading) {
                NSLog(@"STATUS IS LOADING ID ID: %@", attachmentOperation.identifier);
                return;
            }
            __weak typeof(self) weakSelf = self;
            NSOperation *storeOperation = [self.storeService cachedAttachment:attachment messageID:message.ID dialogID:message.dialogID completion:^(NSURL * _Nonnull fileURL, NSData * _Nonnull data) {
                
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                if (attachmentOperation.isCancelled) {
                    NSLog(@"IS CANCELLED FOR STORE SERVICE ID: %@", attachmentOperation.identifier);
                    __strong __typeof(weakOperation) strongOperation = weakOperation;
                    [strongSelf safelyRemoveOperationFromRunning:strongOperation];
                    return;
                }
                if (fileURL) {
                    NSLog(@"HAS FILE URL ID: %@", attachmentOperation.identifier);
                    [strongSelf changeAttachmentStatus:QMAttachmentStatus.loaded forMessageID:message.ID];
                    attachment.localFileURL = fileURL;
                    return;
                }
                
                [strongSelf changeAttachmentStatus:QMAttachmentStatus.downloading forMessageID:message.ID];
                
                [strongSelf.webService downloadMessage:message
                                          attachmentID:attachmentID
                                         progressBlock:progressBlock
                                       completionBlock:^(QMDownloadOperation * _Nonnull downloadOperation) {
                                           
                                           if (!downloadOperation || downloadOperation.isCancelled) {
                                               NSLog(@"2 IS CANCELLED FOR DOWNLOAD SERVICE ID: %@", attachmentOperation.identifier);
                                               [strongSelf changeAttachmentStatus:QMAttachmentStatus.notLoaded forMessageID:message.ID];
                                               return;
                                           }
                                           if (downloadOperation.error) {
                                               NSLog(@"ERROR ID: %@", attachmentOperation.identifier);
                                               [strongSelf changeAttachmentStatus:QMAttachmentStatus.notLoaded forMessageID:message.ID];
                                               
                                               attachmentOperation.error = downloadOperation.error;
                                               
                                               completionBlock(attachmentOperation);
                                           }
                                           else if (downloadOperation.data) {
                                               NSLog(@"NOT CANCELLED SAVE ID: %@", attachmentOperation.identifier);
                                               attachment.ID = attachmentID;
                                               
                                               [strongSelf.storeService saveData:downloadOperation.data
                                                                   forAttachment:attachment
                                                                       cacheType:QMAttachmentCacheTypeDisc|QMAttachmentCacheTypeMemory messageID:message.ID
                                                                        dialogID:message.dialogID
                                                                      completion:^
                                                {
                                                    
                                                    [strongSelf changeAttachmentStatus:QMAttachmentStatus.loaded forMessageID:message.ID];
                                                    if (downloadOperation && !downloadOperation.isCancelled) {
                                                        if (!attachment.isPrepared) {
                                                            [strongSelf prepareAttachment:attachment messageID:message.ID completion:^(UIImage * _Nullable image, Float64 durationSeconds, CGSize size, NSError * _Nullable error, NSString * _Nonnull messageID, BOOL cancelled) {
                                                                if (!cancelled) {
                                                                    if (error) {
                                                                        attachmentOperation.error = error;
                                                                    }
                                                                    else {
                                                                        attachment.image = image;
                                                                        attachment.duration = durationSeconds;
                                                                        
                                                                        [self.storeService updateAttachment:attachment messageID:messageID dialogID:message.dialogID];
                                                                        attachmentOperation.attachment = attachment;
                                                                    }
                                                                    completionBlock(attachmentOperation);
                                                                }
                                                            }];
                                                        }
                                                        else {
                                                            attachmentOperation.attachment = attachment;
                                                            completionBlock(attachmentOperation);
                                                        }
                                                    }
                                                }];
                                           }
                                           
                                       }];
                
            }];
            
            attachmentOperation.storeOperation = storeOperation;
            
            attachmentOperation.cancelBlock = ^{
                __strong __typeof(weakOperation) strongOperation = weakOperation;
                //                [self changeAttachmentStatus:QMAttachmentStatus.notLoaded forMessageID:strongOperation.identifier];
                
                [self.infoService cancellOperationWithID:strongOperation.identifier];
                [self.webService cancellOperationWithID:strongOperation.identifier];
                [self safelyRemoveOperationFromRunning:strongOperation];
            };
        }
    }
}

- (void)safelyRemoveOperationFromRunning:(nullable QMAttachmentOperation *)operation {
    
    @synchronized (self.runningOperations) {
        if (operation) {
            [self.runningOperations removeObjectForKey:operation.identifier];
        }
    }
}


- (NSString *)statusForMessage:(QBChatMessage *)message {
    
    NSString *status = QMAttachmentStatus.notLoaded;
    
    if (self.attachmentsStatuses[message.ID] != nil) {
        return self.attachmentsStatuses[message.ID];
    }
    else {
        QBChatAttachment *attachment = [message.attachments firstObject];
        NSURL *fileURL = [self.storeService fileURLForAttachment:attachment
                                                       messageID:message.ID
                                                        dialogID:message.dialogID];
        if (fileURL != nil) {
            status = QMAttachmentStatus.loaded;
        }
        else {
            BOOL downloading = [self.webService isDownloadingMessageWithID:message.ID];
            if (downloading) {
                status = QMAttachmentStatus.downloading;
            }
        }
        self.attachmentsStatuses[message.ID] = status;
    }
    return status;
}

@end
