//
//  QMMediaInfo.m
//  Pods
//
//  Created by Vitaliy Gurkovsky on 2/26/17.
//
//

#import "QMMediaInfo.h"
#import "QMMediaItem.h"
#import "QMSLog.h"

typedef NS_ENUM(NSUInteger, QMVideoUrlType) {
    QMVideoUrlTypeRemote,
    QMVideoUrlTypeNative
};


@interface QMMediaInfo ()

@property (strong ,nonatomic) AVAsset *asset;
@property (strong, nonatomic) NSURL *assetURL;

@property (assign, nonatomic) QMMediaContentType mediaContentType;

@property (copy, nonatomic) void(^completion)(NSTimeInterval duration, CGSize size, UIImage *image, NSError *error);

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

- (AVAsset*)asset {
    
    __block AVAsset *theAsset = nil;
    dispatch_sync(self.assetQueue, ^(void) {
        theAsset = [[self getAssetInternal] copy];
    });
    
    return theAsset;
}

- (AVAsset*)getAssetInternal
{
    if (_asset == nil) {
        
        NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey : @YES};
        
        _asset = [[AVURLAsset alloc] initWithURL:_assetURL
                                         options:options];
    }
    return  _asset;
}

+ (instancetype)infoFromMediaItem:(QMMediaItem *)mediaItem {
    
    QMMediaInfo *mediaInfo = [[QMMediaInfo alloc] init];
    NSURL *mediaURL = nil;
    
    if (mediaItem.localURL) {
        
        mediaURL = mediaItem.localURL;
    }
    
    else if (mediaItem.remoteURL) {
        
        mediaURL = mediaItem.remoteURL;
    }
    
    mediaInfo.assetURL = mediaURL;
    mediaInfo.prepareStatus = QMMediaPrepareStatusNotPrepared;
    mediaInfo.mediaContentType = mediaItem.contentType;
    mediaInfo.thumbnailImage = mediaItem.image;
    
    if (mediaItem.mediaDuration > 0 && !CGSizeEqualToSize(mediaItem.mediaSize, CGSizeZero) && mediaItem.image) {
        mediaInfo.duration = mediaItem.mediaDuration;
        mediaInfo.mediaSize = mediaItem.mediaSize;
        mediaInfo.prepareStatus = QMMediaPrepareStatusPrepareFinished;
        mediaInfo.thumbnailImage = mediaItem.image;
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
    if (self.prepareStatus == QMMediaPrepareStatusPreparing) {
        dispatch_async(self.assetQueue, ^{
            [self.asset cancelLoading];
        });
    }
}

- (void)prepareWithCompletion:(void(^)(NSTimeInterval duration, CGSize size, UIImage *image, NSError *error))completionBLock {
    
    if (self.prepareStatus == QMMediaPrepareStatusNotPrepared && self.assetURL) {
        
        self.completion = [completionBLock copy];
        self.prepareStatus = QMMediaPrepareStatusPreparing;
        
        [self asynchronouslyLoadURLAsset];
        return;
    }
    
    else if (self.prepareStatus == QMMediaPrepareStatusPrepareFinished) {
        completionBLock(self.duration, self.mediaSize, self.thumbnailImage, nil);
    }
}

- (void)asynchronouslyLoadURLAsset {
    
    __weak __typeof(self)weakSelf = self;
    
    dispatch_async(self.assetQueue, ^(void) {
        
        AVAsset *asset = [self getAssetInternal];
        NSAssert(asset != nil, @"Asset shouldn't be nill");
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        NSArray *requestedKeys = @[@"tracks", @"duration", @"playable"];
        [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
            dispatch_async(self.assetQueue, ^(void) {
                [strongSelf prepareAsset:asset withKeys:requestedKeys];
            });
        }];
    });
}



- (void)generateThumbnailFromAsset:(AVAsset*)thumbnailAsset withSize:(CGSize)size
                 completionHandler:(void (^)(UIImage *thumbnail))handler
{
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:thumbnailAsset];
    
    imageGenerator.appliesPreferredTrackTransform = YES;
    
    if (!CGSizeEqualToSize(size, CGSizeZero)) {
        imageGenerator.maximumSize = size;
    }
    else {
        imageGenerator.maximumSize = CGSizeMake(480, 480);
    }

    NSValue *imageTimeValue = [NSValue valueWithCMTime:CMTimeMake(self.duration < 5 ? ceil(self.duration/2) : 4, 1)];
    
    [imageGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:imageTimeValue] completionHandler:
     ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error)
     {
         if (result == AVAssetImageGeneratorFailed) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 handler(nil);
             });
             
         }
         else {
             UIImage *thumbUIImage = nil;
             if (image) {
                 thumbUIImage = [[UIImage alloc] initWithCGImage:image];
             }
             
             if (handler) {
                 handler(thumbUIImage);
             }
         }
     }];
}

- (void)prepareAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys {
    
    // Make sure that the value of each key has loaded successfully.
    for (NSString *thisKey in requestedKeys) {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed) {
            
            self.prepareStatus = QMMediaPrepareStatusPrepareFailed;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (self.completion) {
                    self.completion(0, CGSizeZero, nil, error);
                }
            });
        }
    }
    
    NSTimeInterval duration = CMTimeGetSeconds(asset.duration);
    CGSize mediaSize = CGSizeZero;
    
    if (self.mediaContentType == QMMediaContentTypeVideo) {
    
        CGFloat videoWidth = [[[asset tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize].width;
        CGFloat videoHeight = [[[asset tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize].height;
        
        mediaSize = CGSizeMake(videoWidth, videoHeight);

        
        if (self.thumbnailImage == nil) {
            
            [self generateThumbnailFromAsset:asset withSize:mediaSize completionHandler:^(UIImage *thumbnail) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.prepareStatus = QMMediaPrepareStatusPrepareFinished;
                    self.duration = duration;
                    self.mediaSize = mediaSize;
                    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                    self.thumbnailImage = thumbnail;
                    if (self.completion) {
                        self.completion(duration, mediaSize, thumbnail, nil);
                    }
                    
                });
            }];
        }
        else {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.prepareStatus = QMMediaPrepareStatusPrepareFinished;
                self.duration = duration;
                self.mediaSize = mediaSize;
                self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                if (self.completion) {
                    self.completion(duration, mediaSize, self.thumbnailImage , nil);
                }
                
            });
        }
        
    }
    else {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.prepareStatus = QMMediaPrepareStatusPrepareFinished;
            self.duration = duration;
            self.mediaSize = mediaSize;
            self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
            
            if (self.completion) {
                self.completion(duration, mediaSize, nil, nil);
            }
            
        });
    }
}

@end
