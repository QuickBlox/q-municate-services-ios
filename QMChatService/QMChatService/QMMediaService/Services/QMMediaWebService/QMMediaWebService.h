//
//  QMMediaWebService.h
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 6/14/17.
//

#import <Foundation/Foundation.h>
#import "QMMediaUploadService.h"
#import "QMMediaDownloadService.h"

@interface QMMediaWebService : NSObject

- (void)downloadDataForAttachment:(QBChatAttachment *)attachment
              withCompletionBlock:(QMAttachmentDataCompletionBlock)completionBlock
                    progressBlock:(QMMediaProgressBlock)progressBlock;

- (void)cancellAllDownloads;
- (void)cancelDownloadOperationForAttachment:(QBChatAttachment *)attachment;

- (void)uploadAttachment:(QBChatAttachment *)attachment
                withData:(NSData *)data
     withCompletionBlock:(QMAttachmentUploadCompletionBlock)completionBlock
           progressBlock:(QMMediaProgressBlock)progressBlock;

- (void)uploadAttachment:(QBChatAttachment *)attachment
             withFileURL:(NSURL *)fileURL
     withCompletionBlock:(QMAttachmentUploadCompletionBlock)completionBlock
           progressBlock:(QMMediaProgressBlock)progressBlock;

@end
