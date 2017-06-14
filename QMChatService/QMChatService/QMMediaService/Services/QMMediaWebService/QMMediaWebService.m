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

@end

@implementation QMMediaWebService

- (instancetype)initWithUploader:(QMMediaUploadService *)uploader
                      downloader:(QMMediaDownloadService *)downloader {
    
    if (self = [super init]) {
        _uploader = uploader;
        _downloader = downloader;
    }
    return self;
}

- (void)downloadDataForAttachment:(QBChatAttachment *)attachment
              withCompletionBlock:(QMAttachmentDataCompletionBlock)completionBlock
                    progressBlock:(QMMediaProgressBlock)progressBlock {
    
    [self.downloader downloadDataForAttachment:attachment
                           withCompletionBlock:completionBlock
                                 progressBlock:progressBlock];
}

- (void)cancellAllDownloads {
    [self.downloader cancellAllDownloads];
}

- (void)cancelDownloadOperationForAttachment:(QBChatAttachment *)attachment {
    [self.downloader cancelDownloadOperationForAttachment:attachment];
}

- (void)uploadAttachment:(QBChatAttachment *)attachment
                withData:(NSData *)data
     withCompletionBlock:(QMAttachmentUploadCompletionBlock)completionBlock
           progressBlock:(QMMediaProgressBlock)progressBlock {
    
    [self.uploader uploadAttachment:attachment withData:data withCompletionBlock:completionBlock progressBlock:progressBlock];
}

- (void)uploadAttachment:(QBChatAttachment *)attachment
             withFileURL:(NSURL *)fileURL
     withCompletionBlock:(QMAttachmentUploadCompletionBlock)completionBlock
           progressBlock:(QMMediaProgressBlock)progressBlock {
    
    [self.uploader uploadAttachment:attachment
                        withFileURL:fileURL
                withCompletionBlock:completionBlock
                      progressBlock:progressBlock];
}

@end
