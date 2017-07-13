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

@interface QMMediaInfoOperation : NSBlockOperation
@property (copy, nonatomic) NSString *identifier;
@property (copy, nonatomic) dispatch_block_t cancelBlock;
@property (strong, nonatomic) QMMediaInfo *mediaInfo;

@end

@interface QMMediaInfoService()
@property (strong, nonatomic) NSOperationQueue *imagesOperationQueue;
@property (strong, nonatomic,readwrite) NSMutableSet *attachmentsInProcess;

@end

@implementation QMMediaInfoService

//MARK: - NSObject

- (instancetype)init {
    
    if (self = [super init]) {
        
        _imagesOperationQueue = [[NSOperationQueue alloc] init];
        _imagesOperationQueue.maxConcurrentOperationCount  = 3;
        _imagesOperationQueue.qualityOfService = NSQualityOfServiceUtility;
        _imagesOperationQueue.name = @"QMServices.videoThumbnailOperationQueue";
    }
    
    return self;
}

- (void)mediaInfoForAttachment:(QBChatAttachment *)attachment
                     messageID:(NSString *)messageID
                    completion:(QMMediaInfoServiceCompletionBlock)completion
{
    
    NSURL *url = attachment.localFileURL?:attachment.remoteURL;
    if (!url) {
        return;
    }
    
    for (QMMediaInfoOperation *o in _imagesOperationQueue.operations) {
        
        if ([o.identifier isEqualToString:messageID]) {
            return;
        }
    }
    
    QMMediaInfoOperation *mediaInfoOperation = [[QMMediaInfoOperation alloc] init];
    mediaInfoOperation.identifier = messageID;
    __weak __typeof(mediaInfoOperation)weakOperation = mediaInfoOperation;
    
    
    mediaInfoOperation.cancelBlock = ^{
        
        [weakOperation.mediaInfo cancel];
        
    };
    
    [mediaInfoOperation addExecutionBlock:^{
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        weakOperation.mediaInfo = [QMMediaInfo infoFromAttachment:attachment messageID:messageID];
        [weakOperation.mediaInfo prepareWithCompletion:^(NSTimeInterval duration, CGSize size, UIImage *image, NSError *error) {
            
            completion(image,duration, size, error, messageID, weakOperation.isCancelled);
            dispatch_semaphore_signal(sem);
            
        }];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }];
    
    
    [self.imagesOperationQueue addOperation:mediaInfoOperation];
}


//MARK: QMCancellableService

- (void)cancellAllOperations {
    
    [self.imagesOperationQueue cancelAllOperations];
}

- (void)cancellOperationWithID:(NSString *)operationID {
    
    for (QMMediaInfoOperation *op in self.imagesOperationQueue.operations) {
        if ([op.identifier isEqualToString:operationID]) {
            [op cancel];
            break;
        }
    }
    
    NSLog(@"_Cancell operation with ID:%@",operationID);
    //    [self.imagesOperationQueue cancelOperationWithID:operationID];
    NSLog(@"Operations = %@", [self.imagesOperationQueue operations]);
}

@end

@implementation QMMediaInfoOperation

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
