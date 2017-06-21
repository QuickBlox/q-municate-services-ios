//
//  QMImageOperation.m
//  Pods
//
//  Created by Vitaliy Gurkovsky on 3/23/17.
//
//

#import "QMImageOperation.h"
#import "QBChatAttachment+QMCustomParameters.h"
#import "DRAsyncOperationSubclass.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface QMImageOperation()

@property (strong, nonatomic) AVAssetImageGenerator *generator;
@property (nonatomic, copy) NSURL *url;
@end


@implementation QMImageOperation

- (void)asyncTask {
    
    //    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime,
    //                                                       CGImageRef image,
    //                                                       CMTime actualTime,
    //                                                       AVAssetImageGeneratorResult result,
    //                                                       NSError *error) {
    //
    //        UIImage *thumb = nil;
    //        if (result == AVAssetImageGeneratorSucceeded) {
    //            thumb = [UIImage imageWithCGImage:image];
    //        }
    //
    //        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    //
    //            if (self.imageOperationCompletionBlock) {
    //                self.imageOperationCompletionBlock(thumb, error);
    //            }
    //
    //            [self finish];
    //        }];
    //    };
    //
    //    NSArray *times = @[[NSValue valueWithCMTime:CMTimeMakeWithSeconds(2,1)]];
    //    [self.generator generateCGImagesAsynchronouslyForTimes:times
    //                                               completionHandler:handler];
    
    
    
    AVAsset *asset = [AVAsset assetWithURL:self.url];
    
    UIImage *thumbnailImage = nil;
    CGSize size = CGSizeZero;
    Float64 durationSeconds = 0.0;
    NSError *error;
    
    if ([self isCancelled]) {
        [self finish];
        return;
    }
    NSLog(@"Start operation with ID:%@", self.operationID);
    
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0)
    {
        self.generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        self.generator.appliesPreferredTrackTransform = YES;
        self.generator.maximumSize = CGSizeMake(200, 200);
        
        durationSeconds = CMTimeGetSeconds([asset duration]);
        
        CMTime actualTime;
        size = [[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
        
        CGImageRef halfWayImage = [self.generator copyCGImageAtTime:kCMTimeZero actualTime:&actualTime error:&error];
        
        if (halfWayImage != NULL) {
            thumbnailImage = [UIImage imageWithCGImage:halfWayImage];
        }
    }
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (self.imageOperationCompletionBlock) {
                self.imageOperationCompletionBlock(thumbnailImage,durationSeconds,size,error);
            }
        });
    
    
    [self finish];
}

- (instancetype)initWithURL:(NSURL *)url
          completionHandler:(nullable QMImageOperationCompletionBlock)completionHandler {
    
    self = [super init];
    
    if (self) {
        
        _url = [url copy];
        _imageOperationCompletionBlock = [completionHandler copy];
    }
    
    return self;
}

- (void)cancel {
    
    [super cancel];
    
    [self.generator cancelAllCGImageGeneration];
    self.imageOperationCompletionBlock = nil;
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"<%@: %p, ID: %@>",
            NSStringFromClass([self class]),
            self,self.operationID];
}

- (void)dealloc {
    
    NSLog(@"dealloc operation with ID: %@",self.operationID);
}

@end
