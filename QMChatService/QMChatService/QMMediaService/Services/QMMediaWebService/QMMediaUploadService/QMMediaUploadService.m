//
//  QMMediaUploadService.m
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/9/17.
//  Copyright © 2017 quickblox. All rights reserved.
//
#import <Quickblox/Quickblox.h>
#import "QMMediaUploadService.h"
#import "QMSLog.h"
#import "QBChatAttachment+QMCustomParameters.h"

@implementation  QMUploadOperation

@end

@interface QMMediaUploadService()

@property (strong, nonatomic) NSOperationQueue *uploadOperationQueue;

@end

@implementation QMMediaUploadService


- (instancetype)init {
    
    if (self  = [super init]) {
        
        self.uploadOperationQueue = [NSOperationQueue new];
        self.uploadOperationQueue.name = @"QM.QMUploadOperationQueue";
        self.uploadOperationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
        self.uploadOperationQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

//MARK: -NSObject
- (void)dealloc {
    
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}


- (void)uploadAttachment:(QBChatAttachment *)attachment
               messageID:(NSString *)messageID
             withFileURL:(NSURL *)fileURL
           progressBlock:(_Nullable QMMediaProgressBlock)progressBlock
         completionBlock:(void(^)(QMUploadOperation *uploadOperation))completion {
    
    NSParameterAssert([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]);
    
    if ([_uploadOperationQueue hasOperationWithID:messageID]) {
        return;
    }
    
    
    QMUploadOperation *uploadOperation =  [QMUploadOperation new];
    uploadOperation.operationID = messageID;
    __weak __typeof(uploadOperation)weakOperation = uploadOperation;
    
    uploadOperation.cancelBlock = ^{
        __strong typeof(weakOperation) strongOperation = weakOperation;
        if (!strongOperation.objectToCancel) {
            completion(strongOperation);
        }
        else {
            [strongOperation.objectToCancel cancel];
        }
    };
    
    [uploadOperation setAsyncOperationBlock:^(dispatch_block_t  _Nonnull finish)
     {
     
         QBRequest *__strong *request = [QBRequest uploadFileWithUrl:fileURL
                             fileName:attachment.name
                          contentType:[attachment stringMIMEType]
                             isPublic:YES
                         successBlock:^(QBResponse * _Nonnull response, QBCBlob * _Nonnull tBlob)
          {
              
              attachment.ID = tBlob.UID;
              attachment.size = tBlob.size;
              
              __strong typeof(weakOperation) strongOperation = weakOperation;
              strongOperation.attachmentID = attachment.ID;
              if (completion) {
                  completion(strongOperation);
              }
              finish();
          } statusBlock:^(QBRequest * _Nonnull request, QBRequestStatus * _Nonnull status)
          {
              
              progressBlock(status.percentOfCompletion);
              NSLog(@"Upload status = %f", status.percentOfCompletion);
              
          } errorBlock:^(QBResponse * _Nonnull response)
          {
              __strong typeof(weakOperation) strongOperation = weakOperation;
              strongOperation.error = response.error.error;
              if (completion) {
                  completion(strongOperation);
              }
              finish();
          }];
         
         __strong typeof(weakOperation) strongOperation = weakOperation;
            strongOperation.objectToCancel = (id <QMCancellableObject>)*request;
     }];
 
    
    [_uploadOperationQueue addOperation:uploadOperation];
    
    
}

- (BOOL)isUplodingMessageWithID:(NSString *)messageID {
    return [_uploadOperationQueue hasOperationWithID:messageID];
}

- (void)uploadAttachment:(QBChatAttachment *)attachment
               messageID:(NSString *)messageID
                withData:(NSData *)data
           progressBlock:(_Nullable QMMediaProgressBlock)progressBlock
         completionBlock:(void(^)(QMUploadOperation *uploadOperation))completion {
    
    NSParameterAssert(data != nil);
    
    for (QMUploadOperation *o in _uploadOperationQueue.operations) {
        
        if ([o.operationID isEqualToString:messageID]) {
            return;
        }
    }
    
    QMUploadOperation *uploadOperation =  [QMUploadOperation new];
    uploadOperation.operationID = messageID;
    
    __weak __typeof(uploadOperation)weakOperation = uploadOperation;
    
    uploadOperation.cancelBlock = ^{
        __strong typeof(weakOperation) strongOperation = weakOperation;
        
        if (!strongOperation.objectToCancel) {
            completion(strongOperation);
        }
        else {
            [strongOperation.objectToCancel cancel];
        }
    };
    
    
    [uploadOperation setAsyncOperationBlock:^(dispatch_block_t  _Nonnull finish)
     {
         weakOperation.objectToCancel = (id <QMCancellableObject>)
         [QBRequest TUploadFile:data
                       fileName:attachment.name
                    contentType:[attachment stringMIMEType]
                       isPublic:NO
                   successBlock:^(QBResponse * _Nonnull response,
                                  QBCBlob * _Nonnull tBlob)
          {
              
              attachment.ID = tBlob.UID;
              attachment.size = tBlob.size;
              
              __strong typeof(weakOperation) strongOperation = weakOperation;
              strongOperation.operationID = tBlob.UID;
              if (completion) {
                  completion(strongOperation);
              }
              finish();
              
          } statusBlock:^(QBRequest * _Nonnull request,
                          QBRequestStatus * _Nullable status)
          {
              
              progressBlock(status.percentOfCompletion);
              
          } errorBlock:^(QBResponse * _Nonnull response)
          {
              __strong typeof(weakOperation) strongOperation = weakOperation;
              strongOperation.error = response.error.error;
              if (completion) {
                  completion(strongOperation);
              }
              finish();
          }];
         
     }];
    
    
    [_uploadOperationQueue addOperation:uploadOperation];
}

- (void)cancellAllOperations {
    [_uploadOperationQueue cancelAllOperations];
}

- (void)cancellOperationWithID:(NSString *)operationID {
    [_uploadOperationQueue cancelOperationWithID:operationID];
}

@end
