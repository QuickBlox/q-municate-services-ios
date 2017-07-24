//
//  QMMediaInfo.m
//  Pods
//
//  Created by Vitaliy Gurkovsky on 2/26/17.
//
//

#import "QMMediaInfo.h"
#import "QMSLog.h"
#import "QBChatAttachment+QMCustomParameters.h"

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

@property (copy, nonatomic) void(^completion)(NSTimeInterval duration, CGSize size, UIImage *image, NSError *error, AVPlayerItem *playerItem);

@property (strong, nonatomic, readwrite) AVPlayerItem *playerItem;
@property (assign, nonatomic, readwrite) CGSize mediaSize;
@property (assign, nonatomic, readwrite) NSTimeInterval duration;
@property (assign, nonatomic, readwrite) QMMediaPrepareStatus prepareStatus;
@property (strong, nonatomic, readwrite) UIImage *thumbnailImage;

@property (strong, nonatomic) dispatch_queue_t assetQueue;

@end

@implementation QMMediaInfo

//MARK - NSObject

- (void)dealloc {
    
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (AVAsset *)asset {
    
    return [self getAssetInternal];;
}

- (AVAsset *)getAssetInternal
{
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
    mediaInfo.thumbnailImage = attachment.image;
    mediaInfo.messageID = messageID;
    
    if (attachment.duration > 0) {
        mediaInfo.duration = attachment.duration;
    }
    
    if (!CGSizeEqualToSize(CGSizeMake(attachment.width, attachment.height), CGSizeZero)) {
        mediaInfo.mediaSize = CGSizeMake(attachment.width, attachment.height);
    }
    if (attachment.image) {
        mediaInfo.thumbnailImage = attachment.image;
    }
    
    return mediaInfo;
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        self.assetQueue = dispatch_queue_create("Asset Queue", DISPATCH_QUEUE_SERIAL);
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

- (void)prepareWithCompletion:(void(^)(NSTimeInterval duration, CGSize size, UIImage *image, NSError *error, AVPlayerItem *item))completionBLock {
    
    if (self.prepareStatus == QMMediaPrepareStatusNotPrepared && self.assetURL) {
        NSLog(@"1 self.prepareStatus == QMMediaPrepareStatusNotPrepared %@", _messageID);
        self.completion = completionBLock;
        self.prepareStatus = QMMediaPrepareStatusPreparing;
        
        [self asynchronouslyLoadURLAsset];
        return;
    }
    
    else if (self.prepareStatus == QMMediaPrepareStatusPrepareFinished) {
         NSLog(@"1 self.prepareStatus == QMMediaPrepareStatusPrepareFinished %@", _messageID);
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.asset];
        completionBLock(self.duration, self.mediaSize, self.thumbnailImage, nil, item);
    }
    NSAssert(NO, @"No condition");
}

- (void)asynchronouslyLoadURLAsset {
    
    //  dispatch_async(self.assetQueue, ^(void) {
    
    AVAsset *asset = [self getAssetInternal];
    NSAssert(asset != nil, @"Asset shouldn't be nill");
    
    
    NSArray *requestedKeys = @[@"tracks", @"duration", @"playable"];
    NSLog(@"2 loadValuesAsynchronouslyForKeys %@", _messageID);
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
       // dispatch_async(strongSelf.assetQueue, ^(void) {
            NSLog(@"3 Completed Load %@", _messageID);
        if (self.prepareStatus == QMMediaPrepareStatusPrepareCancelled) {
            NSLog(@"4 isCancelled %@", _messageID);
            if (self.completion) {
                self.completion(0, CGSizeZero, nil, nil, nil);
            }
            return;
        }
        
        for (NSString *key in requestedKeys) {
            NSError *error = nil;
            AVKeyValueStatus keyStatus = [asset statusOfValueForKey:key error:&error];
            if (keyStatus == AVKeyValueStatusFailed) {
                if (self.completion) {
                    self.prepareStatus = QMMediaPrepareStatusPrepareFailed;
                    self.completion(0, CGSizeZero, nil, error, nil);
                }
                return;
            }
        }
        
            [self prepareAsset:asset withKeys:requestedKeys];
      //  });
    }];
    //  });
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

- (void)prepareAsset:(AVAsset *)asset withKeys:(NSArray *)requestedKeys {
    
    NSLog(@"4 prepareAsset %@", _messageID);
    
    NSTimeInterval duration = CMTimeGetSeconds(asset.duration);
    CGSize mediaSize = CGSizeZero;
    
    if (self.contentType == QMAttachmentContentTypeVideo) {
        
        NSLog(@"5 QMAttachmentContentTypeVideo %@", _messageID);
        if ([asset tracksWithMediaType:AVMediaTypeVideo] > 0) {
            NSLog(@"6 tracksWithMediaType %@", _messageID);
            AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            CGSize videoSize = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
            CGFloat videoWidth = videoSize.width;
            CGFloat videoHeight = videoSize.height;
            
            mediaSize = CGSizeMake(videoWidth, videoHeight);
            
            if (self.thumbnailImage == nil) {
                    NSLog(@"7 Begin imnage generation %@", _messageID);
                __weak typeof(self) weakSelf = self;
                
                [self generateThumbnailFromAsset:asset withSize:mediaSize completionHandler:^(UIImage *thumbnail, NSError *error) {
                    NSLog(@"8 End image generation %@", _messageID);
                         __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (error) {
                        if (strongSelf.completion) {
                            strongSelf.prepareStatus = QMMediaPrepareStatusPrepareFailed;
                            strongSelf.completion(duration, mediaSize, thumbnail, error, nil);
                        }
                        return;
                    }
                    
                        strongSelf.prepareStatus = QMMediaPrepareStatusPrepareFinished;
                        strongSelf.duration = duration;
                        strongSelf.mediaSize = mediaSize;
                        //  self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                        strongSelf.thumbnailImage = thumbnail;
                        if (strongSelf.completion) {
                             AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.asset];
                            strongSelf.completion(duration, mediaSize, thumbnail, nil, item);
                        }
                }];
            }
            else {
                NSLog(@"8 HAS IMAGE: %@", _messageID);
                
                    if (self.completion) {
                        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.asset];
                        self.completion(duration, mediaSize, self.thumbnailImage, nil, item);
                    }
            }
        }
        
        else {
            
            NSLog(@"6 NO tracksWithMediaType %@", _messageID);
                self.prepareStatus = QMMediaPrepareStatusPrepareFinished;
                self.duration = duration;
                self.mediaSize = mediaSize;
                if (self.completion) {
                    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.asset];
                    self.completion(duration, mediaSize, self.thumbnailImage , nil, item);
                }
        }
        
    }
    else {
        
            self.prepareStatus = QMMediaPrepareStatusPrepareFinished;
            self.duration = duration;
            self.mediaSize = mediaSize;
            AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.asset];
            if (self.completion) {
                self.completion(duration, mediaSize, nil, nil, item);
            }
        
    }
}

@end
