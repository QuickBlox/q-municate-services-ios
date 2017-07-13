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


@implementation QMUploadOperation

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

- (void)cancel {
    
    [super cancel];
    
    if (self.cancelBlock) {
        self.cancelBlock();
        
        // TODO: this is a temporary fix to #809.
        // Until we can figure the exact cause of the crash, going with the ivar instead of the setter
        //        self.cancelBlock = nil;
        _cancelBlock = nil;
    }
}

- (void)dealloc {
    
    NSLog(@"%@, class: %@, id: %@", NSStringFromSelector(_cmd), NSStringFromClass(self.class), _identifier);
}

- (NSString *)description {
    
    NSMutableString *result = [NSMutableString stringWithString:[super description]];
    [result appendFormat:@" ->>> %@", _identifier];
    
    return result.copy;
}

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
         completionBlock:(void(^)(QMUploadOperation *downloadOperation))completion {
    
    NSParameterAssert([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]);
    
    for (QMUploadOperation *o in _uploadOperationQueue.operations) {
        
        if ([o.identifier isEqualToString:messageID]) {
            return;
        }
    }
    
    
    QMUploadOperation *uploadOperation =  [QMUploadOperation new];
    uploadOperation.identifier = messageID;
    __weak __typeof(uploadOperation)weakOperation = uploadOperation;
    
    uploadOperation.cancelBlock = ^{
        __strong typeof(weakOperation) strongOperation = weakOperation;
        if (!strongOperation.request) {
            completion(strongOperation);
        }
        else {
        [strongOperation.request cancel];
        }
    };
    
    [uploadOperation addExecutionBlock:^{
        
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        
        weakOperation.request = [QBRequest uploadFileWithUrl:fileURL
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
                                     dispatch_semaphore_signal(sem);
                                     
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
                                     dispatch_semaphore_signal(sem);
                                 }];
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }];
    
    [_uploadOperationQueue addOperation:uploadOperation];
    
    
}


- (void)uploadAttachment:(QBChatAttachment *)attachment
               messageID:(NSString *)messageID
                withData:(NSData *)data
           progressBlock:(_Nullable QMMediaProgressBlock)progressBlock
         completionBlock:(void(^)(QMUploadOperation *downloadOperation))completion {
    
    NSParameterAssert(data != nil);
    
    for (QMUploadOperation *o in _uploadOperationQueue.operations) {
        
        if ([o.identifier isEqualToString:messageID]) {
            return;
        }
    }
    
    QMUploadOperation *uploadOperation =  [QMUploadOperation new];
    uploadOperation.identifier = messageID;
    
    __weak __typeof(uploadOperation)weakOperation = uploadOperation;
    
    uploadOperation.cancelBlock = ^{
         __strong typeof(weakOperation) strongOperation = weakOperation;
        
        if (!strongOperation.request) {
        completion(strongOperation);
        }
        else {
        [weakOperation.request cancel];
        }
    };
    
    
    [uploadOperation addExecutionBlock:^{
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        weakOperation.request =  [QBRequest TUploadFile:data
                                               fileName:attachment.name
                                            contentType:[attachment stringMIMEType]
                                               isPublic:NO
                                           successBlock:^(QBResponse * _Nonnull response,
                                                          QBCBlob * _Nonnull tBlob)
                                  {
                                      
                                      attachment.ID = tBlob.UID;
                                      attachment.size = tBlob.size;
                                      
                                      __strong typeof(weakOperation) strongOperation = weakOperation;
                                      strongOperation.attachmentID = tBlob.UID;
                                      if (completion) {
                                          completion(strongOperation);
                                      }
                                       dispatch_semaphore_signal(sem);
                                      
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
                                      
                                      dispatch_semaphore_signal(sem);
                                  }];
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        
    }];
    
    
    [_uploadOperationQueue addOperation:uploadOperation];

}

@end
