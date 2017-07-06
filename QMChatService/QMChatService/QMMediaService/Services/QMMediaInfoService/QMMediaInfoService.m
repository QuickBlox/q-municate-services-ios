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

@interface QMMediaInfoService() //<QMImageOperationDelegate>
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
    
    if ([self.imagesOperationQueue hasOperationWithID:messageID]) {
        
        return;
    }
    
    QMAsynchronousOperation *mediaInfoOperation = [QMAsynchronousOperation asynchronousOperationWithID:messageID];
    __block QMMediaInfo *mediaInfo ;
    __weak typeof(QMAsynchronousOperation) *weakOperation = mediaInfoOperation;
    
    mediaInfoOperation.operationBlock = ^{
        
        
       mediaInfo = [QMMediaInfo infoFromAttachment:attachment];
        [mediaInfo prepareWithCompletion:^(NSTimeInterval duration, CGSize size, UIImage *image, NSError *error) {
            __strong QMAsynchronousOperation *strongOperation = weakOperation;
            BOOL isCancelled = strongOperation.isCancelled;
            completion(image,duration, size, error, messageID, isCancelled);
     //       if (!isCancelled) {
                 [strongOperation completeOperation];
      //      }
        }];
        
//        AVAsset *asset = [AVAsset assetWithURL:url];
//        __block UIImage *thumbnailImage = nil;
//        __block CGSize size = CGSizeZero;
//        Float64 durationSeconds =  CMTimeGetSeconds([asset duration]);
//        __block NSError *error;
//
//        NSString *tracksKey = @"tracks";
//
//        [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:
//         ^{
//
//             AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
//
//             if (status == AVKeyValueStatusLoaded) {
//                 if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0)
//                 {
//                     generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
//                     generator.appliesPreferredTrackTransform = YES;
//                     generator.maximumSize = CGSizeMake(200, 200);
//
//
//
//                     CMTime actualTime;
//                     size = [[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
//
//                     CGImageRef halfWayImage = [generator copyCGImageAtTime:kCMTimeZero
//                                                                 actualTime:&actualTime
//                                                                      error:&error];
//
//                     if (halfWayImage != NULL) {
//                         thumbnailImage = [UIImage imageWithCGImage:halfWayImage];
//                     }
//
//                     dispatch_async(dispatch_get_main_queue(), ^{
//                         completion(thumbnailImage, durationSeconds, size, error);
//                     });
//
//                     __strong QMAsynchronousOperation *strongOperation = weakOperation;
//                     [strongOperation completeOperation];
//                 }
//                 else {
//                     __strong QMAsynchronousOperation *strongOperation = weakOperation;
//                     [strongOperation completeOperation];
//                     //    NSAssert(NO, @"NO VIDEO TRACKS");
//                     dispatch_async(dispatch_get_main_queue(), ^{
//                         completion(thumbnailImage, durationSeconds, size, error);
//                     });
//                 }
//             }
//             else {
//                 NSLog(@"ERROR %@ %@", messageID ,error);
//                 dispatch_async(dispatch_get_main_queue(), ^{
//                     completion(thumbnailImage, durationSeconds, size, error);
//                 });
//
//                 __strong QMAsynchronousOperation *strongOperation = weakOperation;
//                 [strongOperation completeOperation];
//             }
//         }];
//
    };
    
    mediaInfoOperation.cancellBlock = ^{
        [mediaInfo cancel];
    };
    
    [self.imagesOperationQueue addAsynchronousOperation:mediaInfoOperation atFronOfQueue:YES];
}


//MARK: QMCancellableService

- (void)cancellAllOperations {
    
    [self.imagesOperationQueue cancelAllOperations];
}

- (void)cancellOperationWithID:(NSString *)operationID {
    
    NSLog(@"_Cancell operation with ID:%@",operationID);
    [self.imagesOperationQueue cancelOperationWithID:operationID];
    NSLog(@"Operations = %@", [self.imagesOperationQueue operations]);
}

@end
