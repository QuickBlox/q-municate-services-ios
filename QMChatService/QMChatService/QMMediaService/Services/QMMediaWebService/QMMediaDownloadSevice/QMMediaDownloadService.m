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

@implementation QMDownloadOperation

@end

@interface QMMediaDownloadService()

@property (strong, nonatomic) NSOperationQueue *downloadOperationQueue;


@end

@implementation QMMediaDownloadService

- (void)downloadMessage:(QBChatMessage *)message
                       attachmentID:(NSString *)attachmentID
          progressBlock:(QMMediaProgressBlock)progressBlock
        completionBlock:(void(^)(QMDownloadOperation *downloadOperation))completion {
    
    
    if  ([_downloadOperationQueue hasOperationWithID:message.ID]) {
        return;
    }
    
    
    QMDownloadOperation *downloadOperation =  [QMDownloadOperation new];
    downloadOperation.operationID = message.ID;
    
    __weak __typeof(downloadOperation)weakOperation = downloadOperation;
    
    downloadOperation.cancelBlock = ^{
        __strong typeof(weakOperation) strongOperation = weakOperation;
        NSLog(@"Cancell operation with ID: %@", strongOperation.operationID);
        if (!strongOperation.request) {
            completion(strongOperation);
        }
        [strongOperation.request cancel];
        strongOperation.request = nil;
       // cancellBlock(attachment);
    };
    
    [downloadOperation setOperationBlock:^(dispatch_block_t  _Nonnull finish) {
        NSLog(@"Start Download operation with ID: %@", weakOperation.operationID);
        weakOperation.request = [QBRequest backgroundDownloadFileWithUID:attachmentID
                                                            successBlock:^(QBResponse * _Nonnull response,
                                                                           NSData * _Nonnull fileData)
                                 {
                                     NSLog(@"Complete operation with ID: %@", weakOperation.operationID);
                                  //   completionBlock(messageID, fileData, response.error.error);
                                     __strong typeof(weakOperation) strongOperation = weakOperation;
                                     strongOperation.data = fileData;
                                     completion(strongOperation);
                                     finish();
                                     
                                 } statusBlock:^(QBRequest * _Nonnull request, QBRequestStatus * _Nonnull status) {
                                     if (progressBlock) {
                                         progressBlock(status.percentOfCompletion);
                                     }
                                 } errorBlock:^(QBResponse * _Nonnull response) {
                                     NSLog(@"Error operation with ID: %@", weakOperation.operationID);
                                     __strong typeof(weakOperation) strongOperation = weakOperation;
                                     strongOperation.error = response.error.error;
                                     completion(strongOperation);
                                     finish();
                                 }];
        
    }];
    
    
    [_downloadOperationQueue addOperation:downloadOperation];
    NSLog(@"donwload operation queue %@", self.downloadOperationQueue.operations);
}

- (instancetype)init {
    
    if (self  = [super init]) {
        
        self.downloadOperationQueue = [NSOperationQueue new];
        self.downloadOperationQueue.name = @"QM.QMDownloadOperationQueue";
        self.downloadOperationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
        self.downloadOperationQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

- (void)dealloc {
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}



- (NSOperation *)downloadDataForAttachment:(QBChatAttachment *)attachment
                        messageID:(NSString *)messageID
              withCompletionBlock:(QMAttachmentDataCompletionBlock)completionBlock
                    progressBlock:(QMMediaProgressBlock)progressBlock
                     cancellBlock:(QMAttachmentDownloadCancellBlock)cancellBlock {
    
    
    if  ([_downloadOperationQueue hasOperationWithID:messageID]) {
        return nil;
    }
    
    
  QMDownloadOperation *downloadOperation =  [QMDownloadOperation new];
    downloadOperation.operationID = messageID;
    
    __weak __typeof(downloadOperation)weakOperation = downloadOperation;
    
    downloadOperation.cancelBlock = ^{
           __strong typeof(weakOperation) strongOperation = weakOperation;
         NSLog(@"Cancell operation with ID: %@", strongOperation.operationID);
        if (!strongOperation.request) {
            NSLog(@"NO REQUEST FOR CANCELL operation with ID: %@", strongOperation.operationID);
        }
        [strongOperation.request cancel];
        strongOperation.request = nil;
         cancellBlock(attachment);
    };
    
    [downloadOperation setOperationBlock:^(dispatch_block_t  _Nonnull finish) {
        NSLog(@"Start Download operation with ID: %@", weakOperation.operationID);
        weakOperation.request = [QBRequest backgroundDownloadFileWithUID:attachment.ID
                                                            successBlock:^(QBResponse * _Nonnull response,
                                                                           NSData * _Nonnull fileData)
        {
            NSLog(@"Complete operation with ID: %@", weakOperation.operationID);
            completionBlock(messageID, fileData, response.error.error);
            weakOperation.operationCompletionBlock(messageID, fileData, response.error.error);
            finish();
            
        } statusBlock:^(QBRequest * _Nonnull request, QBRequestStatus * _Nonnull status) {
            if (progressBlock) {
                progressBlock(status.percentOfCompletion);
            }
        } errorBlock:^(QBResponse * _Nonnull response) {
            NSLog(@"Error operation with ID: %@", weakOperation.operationID);
            completionBlock(messageID, nil, response.error.error);
             finish();
            
        }];
        
    }];
    
    
    [_downloadOperationQueue addOperation:downloadOperation];
    NSLog(@"donwload operation queue %@", self.downloadOperationQueue.operations);
    return downloadOperation;
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
