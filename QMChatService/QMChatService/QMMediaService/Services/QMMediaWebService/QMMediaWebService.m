//
//  QMMediaWebService.m
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 6/14/17.
//

#import "QMMediaWebService.h"
#import "QMMediaDownloadService.h"
#import "QMMediaUploadService.h"

@interface QMMediaWebService()

@property (nonatomic, strong) QMMediaUploadService *uploader;
@property (nonatomic, strong) QMMediaDownloadService *downloader;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSNumber *> *messagesWebProgress;
@end

@implementation QMMediaWebService

- (instancetype)init {
    
    QMMediaUploadService *uploader = [QMMediaUploadService new];
    QMMediaDownloadService *downloader = [QMMediaDownloadService new];
    
    return [self initWithUploader:uploader downloader:downloader];
}

- (instancetype)initWithUploader:(QMMediaUploadService *)uploader
                      downloader:(QMMediaDownloadService *)downloader {
    
    if (self = [super init]) {
        
        _messagesWebProgress = [NSMutableDictionary dictionary];
        _uploader = uploader;
        _downloader = downloader;
    }
    return self;
}


- (void)downloadDataForAttachment:(QBChatAttachment *)attachment
                        messageID:(NSString *)messageID
              withCompletionBlock:(QMAttachmentDataCompletionBlock)completionBlock
                    progressBlock:(QMMediaProgressBlock)progressBlock
                     cancellBlock:(QMAttachmentDownloadCancellBlock)cancellBlock  {
    
    [self.downloader downloadDataForAttachment:attachment
                                     messageID:messageID
                           withCompletionBlock:completionBlock
                                 progressBlock:^(float progress) {
                                     self.messagesWebProgress[messageID] = @(progress);
                                     progressBlock(progress);
                                 }
                                  cancellBlock:cancellBlock];
}


- (void)uploadAttachment:(QBChatAttachment *)attachment
               messageID:(NSString *)messageID
                withData:(NSData *)data
     withCompletionBlock:(QMAttachmentUploadCompletionBlock)completionBlock
           progressBlock:(QMMediaProgressBlock)progressBlock {
    
    [self.uploader uploadAttachment:attachment
                           withData:data
                withCompletionBlock:completionBlock
                      progressBlock:^(float progress) {
                          
                          self.messagesWebProgress[messageID] = @(progress);
                          progressBlock(progress);
                      }];
}

- (void)uploadAttachment:(QBChatAttachment *)attachment
               messageID:(NSString *)messageID
             withFileURL:(NSURL *)fileURL
     withCompletionBlock:(QMAttachmentUploadCompletionBlock)completionBlock
           progressBlock:(QMMediaProgressBlock)progressBlock {
    
    [self.uploader uploadAttachment:attachment
                        withFileURL:fileURL
                withCompletionBlock:completionBlock
                      progressBlock:^(float progress) {
                          self.messagesWebProgress[messageID] = @(progress);
                          progressBlock(progress);
                      }];
}


- (CGFloat)progressForMessageWithID:(NSString *)messageID {
    return self.messagesWebProgress[messageID].floatValue;
}


//MARK: - QMCancellableService

- (void)cancellOperationWithID:(NSString *)operationID {
    [self.messagesWebProgress removeObjectForKey:operationID];
    [self.downloader cancellOperationWithID:operationID];
}

- (BOOL)isDownloadingMessageWithID:(NSString *)messageID {
   return  [self.downloader isDownloadingMessageWithID:messageID];
}

- (void)cancellAllOperations {
    
    [self.downloader cancellAllOperations];
}
@end
