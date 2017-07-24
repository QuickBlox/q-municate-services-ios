//
//  QMMediaInfoService.m
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 2/22/17.
//
//

#import "QMMediaInfoService.h"
#import <AVKit/AVKit.h>
//#import "QMImageOperation.h"
#import "QMAsynchronousOperation.h"

#import "QBChatAttachment+QMCustomParameters.h"
#import "QMMediaInfo.h"

@interface QMMediaInfoService()

@property (strong, nonatomic) NSOperationQueue *mediaInfoOperationQueue;
@property (weak, nonatomic, nullable) NSOperation *lastAddedOperation;
@property (strong, nonatomic) NSMutableDictionary *mediaInfoStorage;
@end

@implementation QMMediaInfoService

//MARK: - NSObject

- (instancetype)init {
    
    if (self = [super init]) {
        
        _mediaInfoOperationQueue = [[NSOperationQueue alloc] init];
        _mediaInfoOperationQueue.maxConcurrentOperationCount  = 2;
        _mediaInfoOperationQueue.qualityOfService = NSQualityOfServiceUtility;
        _mediaInfoOperationQueue.name = @"QMServices.mediaInfoOperationQueue";
        _mediaInfoStorage = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)mediaInfoForAttachment:(QBChatAttachment *)attachment
                     messageID:(NSString *)messageID
                    completion:(QMMediaInfoServiceCompletionBlock)completion
{
    
    NSURL *url = attachment.localFileURL?:attachment.remoteURL;
    NSParameterAssert(url);
    
    if ([_mediaInfoOperationQueue hasOperationWithID:messageID]) {
        return;
    }
    
    QMAsynchronousOperation *mediaInfoOperation = [[QMAsynchronousOperation alloc] init];
    mediaInfoOperation.operationID = messageID;
    __weak __typeof(mediaInfoOperation)weakOperation = mediaInfoOperation;
    
    mediaInfoOperation.cancelBlock = ^{
        __strong typeof(weakOperation) strongOperation = weakOperation;
        NSLog(@"Cancell operation with ID: %@", strongOperation.operationID);
        if (!strongOperation.objectToCancel) {
            completion(nil, 0, CGSizeZero, nil, messageID, YES);
        }
        
        [strongOperation.objectToCancel cancel];
        
    };
    
    [mediaInfoOperation setAsyncOperationBlock:^(dispatch_block_t  _Nonnull finish) {
        
        QMMediaInfo *mediaInfo = [QMMediaInfo infoFromAttachment:attachment
                                                       messageID:messageID];
        
        weakOperation.objectToCancel = (id <QMCancellableObject>)mediaInfo;
        
        [mediaInfo prepareWithCompletion:^(NSTimeInterval duration, CGSize size, UIImage *image, NSError *error, AVPlayerItem *item) {
            if (item) {
                @synchronized (self.mediaInfoStorage) {
                    self.mediaInfoStorage[messageID] = item;
                }
            }
            completion(image,duration, size, error, messageID, weakOperation.isCancelled);
            finish();
        }];
    }];
    
    [self.mediaInfoOperationQueue addOperation:mediaInfoOperation];
    
    //LIFO order
    [self.lastAddedOperation addDependency:mediaInfoOperation];
    self.lastAddedOperation = mediaInfoOperation;
}

- (AVPlayerItem *)playerItemForAtatchment:(QBChatAttachment *)att
                                messageID:(NSString *)messageID  {
    AVPlayerItem *item = nil;
    @synchronized (self.mediaInfoStorage) {
        item =  self.mediaInfoStorage[messageID];
    }
    
    return item;
}

//MARK: QMCancellableService

- (void)cancellAllOperations {
    
    [self.mediaInfoOperationQueue cancelAllOperations];
}

- (void)cancellOperationWithID:(NSString *)operationID {
    
    for (QMAsynchronousOperation *op in self.mediaInfoOperationQueue.operations) {
        if ([op.operationID isEqualToString:operationID]) {
            [op cancel];
            break;
        }
    }
    
    NSLog(@"_Cancell operation with ID:%@",operationID);
    //    [self.imagesOperationQueue cancelOperationWithID:operationID];
    NSLog(@"Operations = %@", [self.mediaInfoOperationQueue operations]);
}

@end

