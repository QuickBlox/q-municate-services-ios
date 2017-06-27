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


@interface QMMediaInfoService() //<QMImageOperationDelegate>
@property (strong, nonatomic) NSOperationQueue *imagesOperationQueue;
@property (strong, nonatomic,readwrite) NSMutableSet *attachmentsInProcess;

@end

@implementation QMMediaInfoService

//MARK: - NSObject

- (instancetype)init {
    
    if (self = [super init]) {
        
        _imagesOperationQueue = [[NSOperationQueue alloc] init];
        _imagesOperationQueue.maxConcurrentOperationCount  = 1;
        _imagesOperationQueue.qualityOfService = NSQualityOfServiceUtility;
        _imagesOperationQueue.name = @"QMServices.videoThumbnailOperationQueue";
        
    }
    
    return self;
}

- (void)mediaInfoForAttachment:(QBChatAttachment *)attachment
                     messageID:(NSString *)messageID
                    completion:(QMMediaInfoServiceCompletionBlock)completion {
    
    NSURL *url = attachment.localFileURL?:attachment.remoteURL;
    if (!url) {
        return;
    }
    
    QMAsynchronousOperation *mediaInfoOperation = [QMAsynchronousOperation asynchronousOperationWithID:messageID queue:self.imagesOperationQueue];
  __block AVAssetImageGenerator *generator;
__weak typeof(QMAsynchronousOperation) *weakOperation = mediaInfoOperation;
    
    mediaInfoOperation.operationBlock = ^{
        
        AVAsset *asset = [AVAsset assetWithURL:url];
        UIImage *thumbnailImage = nil;
            CGSize size = CGSizeZero;
            Float64 durationSeconds = 0.0;
            NSError *error;
        
        
        
            if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0)
            {
                generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
                 generator.appliesPreferredTrackTransform = YES;
                generator.maximumSize = CGSizeMake(200, 200);
                
                durationSeconds = CMTimeGetSeconds([asset duration]);
                
                CMTime actualTime;
                size = [[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
                
                CGImageRef halfWayImage = [generator copyCGImageAtTime:kCMTimeZero actualTime:&actualTime error:&error];
                
                if (halfWayImage != NULL) {
                    thumbnailImage = [UIImage imageWithCGImage:halfWayImage];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                      completion(thumbnailImage, durationSeconds, size, error);
                });
                
                __strong QMAsynchronousOperation *strongOperation = weakOperation;
                [strongOperation completeOperation];
            }
    };
    
    mediaInfoOperation.cancellBlock = ^{
        [generator cancelAllCGImageGeneration];
    };
    
}


//- (void)videoThumbnailForAttachment:(QBChatAttachment *)attachment
//                         completion:(void(^)(UIImage *image, NSError *error))completion {
//
////    NSURL *remoteURL = attachment.remoteURL;
////    if (!remoteURL) {
////        return;
////    }
////    for (QMImageOperation *operationInQueue in self.imagesOperationQueue.operations) {
////        if ([operationInQueue.operationID isEqualToString:attachment.ID]) {
////            return;
////        }
////    }
////
////    QMImageOperation *imageOperation =
////    [[QMImageOperation alloc] initWithURL:attachment.remoteURL
////                        completionHandler:^(UIImage * _Nullable image,
////                                            Float64 durationSeconds,
////                                            CGSize size,
////                                            NSError * _Nullable error) {
////
////
////                            if (completion) {
////                                completion(image, error);
////                            }
////                        }];
////    imageOperation.delegate = self;
////    imageOperation.operationID = attachment.ID;
////    [self.imagesOperationQueue addOperation:imageOperation];
//
//}

- (void)cancellAllOperations {
    [self.imagesOperationQueue cancelAllOperations];
}
- (void)cancellOperationWithID:(NSString *)operationID {
    
    [self.imagesOperationQueue cancelOperationWithID:operationID];
}

//- (void)operation:(QMImageOperation *)imageOperation didFinishWithSucess:(UIImage *)image {
//    NSLog(@"didFinishWithSucess %@", imageOperation.operationID);
//}
//- (void)operation:(QMImageOperation *)imageOperation didFinishWithError:(NSError *)error {
//    NSLog(@"didFinishWithError %@", imageOperation.operationID);
//}
//
//- (void)operationDidCancell:(QMImageOperation *)imageOperation {
//    NSLog(@"operationDidCancell %@", imageOperation.operationID);
//}

@end
