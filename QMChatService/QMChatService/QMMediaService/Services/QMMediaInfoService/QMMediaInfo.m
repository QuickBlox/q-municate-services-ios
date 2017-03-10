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
    QMVideoUrlTypeNative,
    QMVideoUrlTypeLiveStream,
    QMVideoUrlTypeAsset
};


@interface QMMediaInfo ()

@property (strong ,nonatomic) AVURLAsset *asset;

@property (assign, nonatomic) BOOL isVideoUrlChanged;
@property (assign, nonatomic) QMMediaContentType mediaContentType;
@property (strong, nonatomic, readwrite) AVPlayerItem *playerItem;

@property (strong, nonatomic, readwrite) NSURL *actualVideoPlayingUrl;
@property (assign, nonatomic, readwrite) QMVideoUrlType actualVideoUrlType;

@property (copy, nonatomic) void(^completion)(NSError *error);

@property (assign, nonatomic, readwrite) CGSize mediaSize;
@property (assign, nonatomic, readwrite) NSTimeInterval duration;
@property (assign, nonatomic, readwrite) BOOL isReady;

@property (strong, nonatomic, readwrite) UIImage *image;
@property (assign, nonatomic, readwrite) QMVideoItemPrepareStatus prepareStatus;

@property (strong, nonatomic) dispatch_queue_t prepareQueue;

@end

@implementation QMMediaInfo

//MARK - NSObject
- (void)dealloc {
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

+ (instancetype)infoFromMediaItem:(QMMediaItem *)mediaItem {
    
    QMMediaInfo *mediaInfo = [[QMMediaInfo alloc] init];
    NSURL *mediaURL = nil;
    
    if (mediaItem.localURL) {
        
        mediaURL = mediaItem.localURL;
        mediaInfo.actualVideoUrlType = QMVideoUrlTypeNative;
    }
    
    else if (mediaItem.remoteURL) {
        
        mediaURL = mediaItem.remoteURL;
        mediaInfo.actualVideoUrlType = QMVideoUrlTypeRemote;
    }
    
    NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:mediaURL options:options];
    
    mediaInfo.prepareStatus = QMVideoItemPrepareStatusNotPrepared;
    mediaInfo.mediaContentType = mediaItem.contentType;
    mediaInfo.asset = asset;
    if (mediaItem.mediaDuration > 0) {
        mediaInfo.duration = mediaItem.mediaDuration;
    }
    
    return mediaInfo;
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        self.prepareQueue = dispatch_queue_create("Prepare Queue", DISPATCH_QUEUE_SERIAL);;
    }
    return self;
}

- (void)prepareWithCompletion:(void(^)(NSError *error))completionBLock {
    
    if (self.completion) {
        self.completion = nil;
    }
    
    if (self.asset && self.prepareStatus == QMVideoItemPrepareStatusNotPrepared) {
        
        self.completion = [completionBLock copy];
        self.prepareStatus = QMVideoItemPrepareStatusPreparing;
        
        [self asynchronouslyLoadURLAsset:self.asset];
        return;
    }
    
    else if (self.prepareStatus == QMVideoItemPrepareStatusPrepareFinished) {
        completionBLock(nil);
    }
}

- (void)asynchronouslyLoadURLAsset:(AVAsset *)asset {
    dispatch_async(self.prepareQueue, ^(void) {
        NSAssert(asset != nil, @"Asset shouldn't be nill");
        
        NSArray *requestedKeys = @[@"tracks", @"duration", @"playable"];
        
        __weak __typeof(self)weakSelf = self;
        
        /// Tells the asset to load the values of any of the specified keys that are not already loaded.
        [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
            
            dispatch_async(self.prepareQueue, ^(void) {
                
                [self prepareAsset:self.asset withKeys:requestedKeys];
            });
            
        }];
    });
}

- (void)prepareAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys {
    
    
    
    // Make sure that the value of each key has loaded successfully.
    for (NSString *thisKey in requestedKeys) {
        
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed) {
            
            self.prepareStatus = QMVideoItemPrepareStatusPrepareFailed;
            
            if (self.completion) {
                self.completion(error);
            }
        }
    }
    
    NSError *error;
    
    self.duration = CMTimeGetSeconds(asset.duration);

    if (self.mediaContentType == QMMediaContentTypeVideo) {
        CGFloat videoWidth = [[[asset tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize].width;
        CGFloat videoHeight = [[[asset tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize].height;
        
        if (self.sizeObserver) {
            self.sizeObserver(CGSizeMake(videoWidth, videoHeight));
        }
        self.mediaSize = CGSizeMake(videoWidth, videoHeight);
    }
    
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    self.prepareStatus = QMVideoItemPrepareStatusPrepareFinished;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.completion) {
            self.completion(nil);
        }
        
    });
}


#pragma mark - getters and setters
- (void)setAsset:(AVURLAsset *)asset
{
    _asset = asset;
    
    if (asset) {
        self.isVideoUrlChanged = YES;
        self.actualVideoUrlType = QMVideoUrlTypeAsset;
    }
}

- (UIImage*)copyImageFromCGImage:(CGImageRef)image croppedToSize:(CGSize)size
{
    UIImage *thumbUIImage = nil;
    
    CGRect thumbRect = CGRectMake(0.0, 0.0, CGImageGetWidth(image), CGImageGetHeight(image));
    CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(size, thumbRect);
    cropRect.origin.x = round(cropRect.origin.x);
    cropRect.origin.y = round(cropRect.origin.y);
    cropRect = CGRectIntegral(cropRect);
    CGImageRef croppedThumbImage = CGImageCreateWithImageInRect(image, cropRect);
    thumbUIImage = [[UIImage alloc] initWithCGImage:croppedThumbImage];
    CGImageRelease(croppedThumbImage);
    
    return thumbUIImage;
}


@end
