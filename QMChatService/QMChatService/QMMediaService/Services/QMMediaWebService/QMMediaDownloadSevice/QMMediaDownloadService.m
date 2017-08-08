//
//  QMMediaDownloadService.m
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/7/17.
//  Copyright © 2017 quickblox. All rights reserved.
//


#import "QMMediaDownloadService.h"
#import "QMMediaBlocks.h"
#import "QMSLog.h"

@interface QMDownloadOperation()

@property  (assign, nonatomic) UIBackgroundTaskIdentifier bgTaskId;
@end

@implementation QMDownloadOperation
@end

@interface QMMediaDownloadService()
@property (strong, nonatomic) NSOperationQueue *downloadOperationQueue;
@end

@implementation QMMediaDownloadService

- (instancetype)init {
    
    if (self  = [super init]) {
        
        _downloadOperationQueue = [NSOperationQueue new];
        _downloadOperationQueue.name = @"QM.QMDownloadOperationQueue";
        _downloadOperationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
        _downloadOperationQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

- (void)downloadAttachmentWithID:(NSString *)attachmentID
                       messageID:(NSString *)messageID
                   progressBlock:(QMAttachmentProgressBlock)progressBlock
                 completionBlock:(void(^)(QMDownloadOperation *downloadOperation))completion {
    
    NSParameterAssert(attachmentID.length);
    NSParameterAssert(messageID.length);
    
    if  ([_downloadOperationQueue hasOperationWithID:messageID]) {
        return;
    }
    
    QMDownloadOperation *downloadOperation =  [QMDownloadOperation new];
    downloadOperation.operationID = messageID;
    
    __weak __typeof(downloadOperation)weakOperation = downloadOperation;
    
    downloadOperation.cancelBlock = ^{
        __strong typeof(weakOperation) strongOperation = weakOperation;
        NSLog(@"Cancell operation with ID: %@", strongOperation.operationID);
        if (!strongOperation.objectToCancel) {
            completion(strongOperation);
        }
        [strongOperation.objectToCancel cancel];
        strongOperation.objectToCancel = nil;
    };
    
    [downloadOperation setAsyncOperationBlock:^(dispatch_block_t _Nonnull finish) {
        NSLog(@"Start Download operation with ID: %@", weakOperation.operationID);
        
        UIApplication *application = [UIApplication sharedApplication];
        NSLog(@"Begin background task %@", messageID);
        __strong typeof(weakOperation) strongOperation = weakOperation;
        strongOperation.bgTaskId = [application beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"END background task %@", messageID);
            [application endBackgroundTask:strongOperation.bgTaskId];
            strongOperation.bgTaskId = UIBackgroundTaskInvalid;
        }];
        
        weakOperation.objectToCancel = (id <QMCancellableObject>)[QBRequest backgroundDownloadFileWithUID:attachmentID
                                                                                             successBlock:^(QBResponse * _Nonnull response,
                                                                                                            NSData * _Nonnull fileData)
                                                                  {
                                                                      NSLog(@"Complete operation with ID: %@", weakOperation.operationID);
                                                                      
                                                                      __strong typeof(weakOperation) strongOperation = weakOperation;
                                                                      strongOperation.data = fileData;
                                                                      completion(strongOperation);
                                                                      NSLog(@"END background task inside %@", messageID);
                                                                      
                                                                      [application endBackgroundTask:strongOperation.bgTaskId];
                                                                      strongOperation.bgTaskId = UIBackgroundTaskInvalid;
                                                                      
                                                                      finish();
                                                                  } statusBlock:^(QBRequest * _Nonnull request, QBRequestStatus * _Nonnull status) {
                                                                      if (progressBlock) {
                                                                          NSLog(@"donwload progress %f",status.percentOfCompletion);
                                                                          progressBlock(status.percentOfCompletion);
                                                                      }
                                                                  } errorBlock:^(QBResponse * _Nonnull response) {
                                                                      
                                                                      NSLog(@"Error operation with ID: %@", weakOperation.operationID);
                                                                      __strong typeof(weakOperation) strongOperation = weakOperation;
                                                                      strongOperation.error = response.error.error;
                                                                      completion(strongOperation);
                                                                      NSLog(@"END background task inside error %@", messageID);
                                                                      [application endBackgroundTask:strongOperation.bgTaskId];
                                                                      strongOperation.bgTaskId = UIBackgroundTaskInvalid;
                                                                      
                                                                      finish();
                                                                  }];
    }];
    
    
    [_downloadOperationQueue addOperation:downloadOperation];
    NSLog(@"donwload operation queue %@", self.downloadOperationQueue.operations);
}

- (void)dealloc {
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
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
