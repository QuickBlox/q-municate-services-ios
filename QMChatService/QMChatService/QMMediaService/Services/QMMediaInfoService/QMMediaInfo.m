//
//  QMMediaInfo.m
//
//
//  Created by Vitaliy Gurkovsky on 2/26/17.
//
//

#import "QMMediaInfo.h"
#import "QMSLog.h"
#import "QBChatAttachment+QMCustomParameters.h"
#import "QMTimeOut.h"

typedef NS_ENUM(NSUInteger, QMVideoUrlType) {
    QMVideoUrlTypeRemote,
    QMVideoUrlTypeNative
};


@interface QMMediaInfo ()

@property (strong ,nonatomic) AVAsset *asset;
@property (strong, nonatomic) NSURL *assetURL;
@property (copy, nonatomic) NSString *messageID;
@property (assign, nonatomic) QMAttachmentContentType contentType;
@property (strong, nonatomic) AVAssetImageGenerator *imageGenerator;
@property (strong, nonatomic) QMTimeOut *preloadTimeout;
@property (copy, nonatomic) void(^completion)(NSTimeInterval duration, CGSize size, UIImage *image, NSError *error);

@property (assign, nonatomic, readwrite) QMMediaPrepareStatus prepareStatus;


@property (strong, nonatomic) dispatch_queue_t assetQueue;

@end

@implementation QMMediaInfo

//MARK - NSObject

- (void)dealloc {
    
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
    [self cancel];
    _completion = nil;
}

- (AVAsset *)asset {
    
    if (_asset == nil) {
        
        NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey : @YES};
        _asset = [[AVURLAsset alloc] initWithURL:_assetURL
                                         options:options];
    }
    
    return  _asset;
}

+ (instancetype)infoFromAttachment:(QBChatAttachment *)attachment messageID:(NSString *)messageID {
    
    QMMediaInfo *mediaInfo = [[QMMediaInfo alloc] init];
    NSURL *mediaURL = nil;
    
    if (attachment.localFileURL) {
        mediaURL = attachment.localFileURL;
    }
    else if (attachment.remoteURL) {
        mediaURL = attachment.remoteURL;
    }
    
    mediaInfo.assetURL = mediaURL;
    mediaInfo.prepareStatus = QMMediaPrepareStatusNotPrepared;
    mediaInfo.contentType = attachment.contentType;
    mediaInfo.messageID = messageID;
    return mediaInfo;
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        _assetQueue = dispatch_queue_create("Asset Queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)cancel {
    
    if (self.prepareStatus != QMMediaPrepareStatusPrepareCancelled) {
        
        self.prepareStatus = QMMediaPrepareStatusPrepareCancelled;
        [self.asset cancelLoading];
        [self.imageGenerator cancelAllCGImageGeneration];
    }
}

- (void)prepareWithTimeOut:(NSTimeInterval)timeOutInterval
                completion:(void(^)(NSTimeInterval duration,
                                    CGSize size,
                                    UIImage *image,
                                    NSError *error))completionBlock {
    
    if (self.prepareStatus == QMMediaPrepareStatusNotPrepared && self.assetURL) {
        NSLog(@"1 self.prepareStatus == QMMediaPrepareStatusNotPrepared %@", _messageID);
        self.completion = completionBlock;
        self.prepareStatus = QMMediaPrepareStatusPreparing;
        
        __weak typeof(self) weakSelf = self;
        
        self.preloadTimeout = [[QMTimeOut alloc] initWithTimeInterval:timeOutInterval
                                                                queue:nil];
        [self.preloadTimeout startWithFireBlock:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf cancel];
            NSError *error = [NSError errorWithDomain:@"QMerror" code:0 userInfo:nil];
            completionBlock(0, CGSizeZero, nil, error);
        }];
        
        [self asynchronouslyLoadURLAsset];
    }
}

- (void)asynchronouslyLoadURLAsset {
    
    NSArray *requestedKeys = @[@"tracks", @"duration", @"playable"];
    NSLog(@"2 loadValuesAsynchronouslyForKeys %@", _messageID);
    
    __weak typeof(self) weakSelf = self;
    
    [self.asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        AVAsset *asset = strongSelf.asset;
        NSLog(@"3 Completed Load %@", _messageID);
        if (strongSelf.prepareStatus == QMMediaPrepareStatusPrepareCancelled) {
            NSLog(@"4 isCancelled %@", _messageID);
            return;
        }
        
        for (NSString *key in requestedKeys) {
            NSError *error = nil;
            AVKeyValueStatus keyStatus = [asset statusOfValueForKey:key error:&error];
            if (keyStatus == AVKeyValueStatusFailed) {
                if (strongSelf.completion) {
                    [strongSelf.preloadTimeout cancelTimeout];
                    strongSelf.prepareStatus = QMMediaPrepareStatusPrepareFailed;
                    strongSelf.completion(0, CGSizeZero, nil, error);
                }
                return;
            }
        }
        
        [strongSelf prepareAsset:asset];
    }];
    
}

- (void)generateThumbnailFromAsset:(AVAsset *)thumbnailAsset withSize:(CGSize)size
                 completionHandler:(void (^)(UIImage *thumbnail, NSError *error))handler
{
    _imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:thumbnailAsset];
    
    _imageGenerator.appliesPreferredTrackTransform = YES;
    
    if (!CGSizeEqualToSize(size, CGSizeZero)) {
        
        BOOL isVerticalVideo = size.width < size.height;
        
        size = isVerticalVideo ? CGSizeMake(142.0, 270.0) : CGSizeMake(270.0, 142.0);
    }
    
    _imageGenerator.maximumSize = size;
    NSValue *imageTimeValue = [NSValue valueWithCMTime:CMTimeMake(0, 1)];
    
    [_imageGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:imageTimeValue] completionHandler:
     ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error)
     {
         if (result == AVAssetImageGeneratorFailed || result == AVAssetImageGeneratorCancelled) {
             NSLog(@"7 image gemenaritonWithResult: %@ %@",@"Failed or AVAssetImageGeneratorCancelled", _messageID);
             
             handler(nil, error);
         }
         else {
             NSLog(@"7 image gemenaritonWithResult: %@ %@",@"Sucess", _messageID);
             UIImage *thumbUIImage = nil;
             if (image) {
                 thumbUIImage = [[UIImage alloc] initWithCGImage:image];
             }
             
             if (handler) {
                 handler(thumbUIImage, nil);
             }
         }
     }];
}

- (void)prepareAsset:(AVAsset *)asset {
    
    NSLog(@"4 prepareAsset %@", _messageID);
    
    NSTimeInterval duration = CMTimeGetSeconds(asset.duration);
    CGSize mediaSize = CGSizeZero;
    
    if (self.contentType == QMAttachmentContentTypeVideo) {
        
        NSLog(@"5 QMAttachmentContentTypeVideo %@", _messageID);
        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if (videoTracks.count > 0) {
            NSLog(@"6 tracksWithMediaType %@", _messageID);
            AVAssetTrack *videoTrack = [videoTracks firstObject];
            CGSize videoSize = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
            CGFloat videoWidth = videoSize.width;
            CGFloat videoHeight = videoSize.height;
            
            mediaSize = CGSizeMake(videoWidth, videoHeight);
            
            NSLog(@"7 Begin imnage generation %@", _messageID);
            __weak typeof(self) weakSelf = self;
            
            [self generateThumbnailFromAsset:asset withSize:mediaSize completionHandler:^(UIImage *thumbnail, NSError *error) {
                NSLog(@"8 End image generation %@", _messageID);
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (strongSelf.prepareStatus == QMMediaPrepareStatusPrepareCancelled) {
                    return;
                }
                if (error) {
                    if (strongSelf.completion) {
                        [strongSelf.preloadTimeout cancelTimeout];
                        strongSelf.prepareStatus = QMMediaPrepareStatusPrepareFailed;
                        strongSelf.completion(duration, mediaSize, thumbnail, error);
                    }
                    return;
                }
                
                strongSelf.prepareStatus = QMMediaPrepareStatusPrepareFinished;
                if (strongSelf.completion) {
                    [strongSelf.preloadTimeout cancelTimeout];
                    strongSelf.completion(duration, mediaSize, thumbnail, nil);
                }
            }];
        }
        else {
            
            NSLog(@"6 NO tracksWithMediaType %@", _messageID);
            self.prepareStatus = QMMediaPrepareStatusPrepareFinished;
            if (self.completion) {
                [self.preloadTimeout cancelTimeout];
                self.completion(duration, mediaSize, nil , nil);
            }
        }
    }
    else {
        
        self.prepareStatus = QMMediaPrepareStatusPrepareFinished;
        if (self.completion) {
            [self.preloadTimeout cancelTimeout];
            self.completion(duration, mediaSize, nil, nil);
        }
    }
}

@end
