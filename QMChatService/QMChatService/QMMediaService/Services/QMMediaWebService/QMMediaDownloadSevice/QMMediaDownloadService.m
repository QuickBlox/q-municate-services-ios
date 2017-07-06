//
//  QMMediaDownloadService.m
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/7/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import "QMMediaDownloadServiceDelegate.h"
#import "QMMediaDownloadService.h"

#import "QMMediaBlocks.h"
#import "QMSLog.h"
#import "QMMediaError.h"
#import "QMAsynchronousOperation.h"

@interface QMMediaDownloadService()

@property (strong, nonatomic) NSOperationQueue *downloadOperationQueue;

@end

@implementation QMMediaDownloadService

- (instancetype)init {
    
    if (self  = [super init]) {
        
        self.downloadOperationQueue = [NSOperationQueue new];
        self.downloadOperationQueue.name = @"QM.QMDownloadOperationQueue";
        self.downloadOperationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
        self.downloadOperationQueue.maxConcurrentOperationCount = 2;
    }
    
    return self;
}

- (void)dealloc {
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}



- (void)downloadDataForAttachment:(QBChatAttachment *)attachment
                        messageID:(NSString *)messageID
              withCompletionBlock:(QMAttachmentDataCompletionBlock)completionBlock
                    progressBlock:(QMMediaProgressBlock)progressBlock
                     cancellBlock:(QMAttachmentDownloadCancellBlock)cancellBlock {
    
    QMAsynchronousOperation *operation =
    [QMAsynchronousOperation asynchronousOperationWithID:messageID];
    
    if (operation) {
        
        __weak typeof(QMAsynchronousOperation) *weakOperation = operation;
        __block  QBRequest *request;
        operation.operationBlock = ^{
            
            request =
            [QBRequest backgroundDownloadFileWithUID:attachment.ID
                                       successBlock:^(QBResponse *response, NSData *fileData)
             {
                 
                 if (fileData) {
                     completionBlock(attachment.ID, fileData, nil);
                 }
                 __strong QMAsynchronousOperation *strongOperation = weakOperation;
                 //     NSLog(@"COMPLETE %@, %d", attachmentID, --operationsInprogress);
                 [strongOperation completeOperation];
                 NSLog(@"_COMPLETE %@", messageID);
             } statusBlock:^(QBRequest *request, QBRequestStatus *status) {
                 
                 progressBlock(status.percentOfCompletion);
                 
             } errorBlock:^(QBResponse *response) {
                 
                 QMMediaError *error = [QMMediaError errorWithResponse:response];
                 completionBlock(attachment.ID, nil, error);
                 
                 __strong QMAsynchronousOperation *strongOperation = weakOperation;
                 [strongOperation completeOperation];
                 
             }];
        };
        
        
        operation.cancellBlock = ^{
            NSLog(@"_Cancell %@", messageID);
            [request cancel];
            cancellBlock(attachment);
        };
    }
    
    [self.downloadOperationQueue addAsynchronousOperation:operation atFronOfQueue:YES];
}


- (BOOL)isDownloadingMessageWithID:(NSString *)messageID {
    return [self.downloadOperationQueue hasOperationWithID:messageID];
}
//MARK: - QMCancellableService

- (void)cancellOperationWithID:(NSString *)operationID {
    
    [self.downloadOperationQueue cancelOperationWithID:operationID];
}

- (void)cancellAllOperations {
    
    [self.downloadOperationQueue cancelAllOperations];
}

@end
