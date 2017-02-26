//
//  QMMediaInfo.m
//  Pods
//
//  Created by Vitaliy Gurkovsky on 2/26/17.
//
//

#import "QMMediaInfo.h"
#import "QMMediaItem.h"

typedef NS_ENUM(NSUInteger, CTVideoViewDownloadStrategy) {
    CTVideoViewDownloadStrategyNoDownload, // no download
    CTVideoViewDownloadStrategyDownloadOnlyForeground,
    CTVideoViewDownloadStrategyDownloadForegroundAndBackground,
};

typedef NS_ENUM(NSUInteger, CTVideoViewVideoUrlType) {
    CTVideoViewVideoUrlTypeRemote,
    CTVideoViewVideoUrlTypeNative,
    CTVideoViewVideoUrlTypeLiveStream,
    CTVideoViewVideoUrlTypeAsset,
};

typedef NS_ENUM(NSUInteger, CTVideoViewContentMode) {
    CTVideoViewContentModeResizeAspect, // default, same as AVLayerVideoGravityResizeAspect
    CTVideoViewContentModeResizeAspectFill, // same as AVLayerVideoGravityResizeAspectFill
    CTVideoViewContentModeResize, // same as same as AVLayerVideoGravityResize
};

typedef NS_ENUM(NSUInteger, CTVideoViewOperationButtonType) {
    CTVideoViewOperationButtonTypePlay,
    CTVideoViewOperationButtonTypePause,
    CTVideoViewOperationButtonTypeRetry
};

typedef NS_ENUM(NSUInteger, CTVideoViewStalledStrategy) {
    CTVideoViewStalledStrategyPlay,
    CTVideoViewStalledStrategyDelegateCallback,
};

typedef NS_ENUM(NSUInteger, CTVideoViewPrepareStatus) {
    CTVideoViewPrepareStatusNotInitiated,
    CTVideoViewPrepareStatusNotPrepared,
    CTVideoViewPrepareStatusPreparing,
    CTVideoViewPrepareStatusPrepareFinished,
    CTVideoViewPrepareStatusPrepareFailed,
};

typedef NS_ENUM(NSUInteger, CTVideoViewPlayControlDirection) {
    CTVideoViewPlayControlDirectionMoveForward,
    CTVideoViewPlayControlDirectionMoveBackward,
};
@protocol CTVideoViewOperationDelegate <NSObject>

@optional
- (void)videoViewWillStartPrepare;
- (void)videoViewDidFinishPrepare;
- (void)videoViewDidFailPrepareWithError:(NSError *)error;

- (void)videoViewWillStartPlaying;;
- (void)videoViewDidStartPlaying; // will call this method when the video is **really** playing.
- (void)videoViewStalledWhilePlaying;
- (void)videoViewDidFinishPlaying;

- (void)videoViewWillPause;
- (void)videoViewDidPause;

- (void)videoViewWillStop;
- (void)videoViewDidStop;

@end


static void * kCTVideoViewKVOContext = &kCTVideoViewKVOContext;


@interface QMMediaInfo ()

@property (nonatomic, strong) AVURLAsset *asset;

@property (nonatomic, assign) BOOL isVideoUrlChanged;

@property (nonatomic, assign, readwrite) CTVideoViewPrepareStatus prepareStatus;
@property (nonatomic, assign, readwrite) CTVideoViewVideoUrlType videoUrlType;
@property (nonatomic, strong, readwrite) NSURL *actualVideoPlayingUrl;
@property (nonatomic, assign, readwrite) CTVideoViewVideoUrlType actualVideoUrlType;
@property (nonatomic, weak) id<CTVideoViewOperationDelegate> operationDelegate;

@property (copy, nonatomic) void(^completion)(NSError *error);

@end



@implementation QMMediaInfo

NSString * const kCTVideoViewShouldPlayRemoteVideoWhenNotWifi = @"kCTVideoViewShouldPlayRemoteVideoWhenNotWifi";

NSString * const kCTVideoViewKVOKeyPathPlayerItemStatus = @"player.currentItem.status";
NSString * const kCTVideoViewKVOKeyPathPlayerItemDuration = @"player.currentItem.duration";
NSString * const kCTVideoViewKVOKeyPathLayerReadyForDisplay = @"layer.readyForDisplay";


//MARK - NSObject
+ (instancetype)infoFromMediaItem:(QMMediaItem *)mediaItem {
    
    QMMediaInfo *mediaInfo = [[QMMediaInfo alloc] init];
    NSURL *mediaURL = nil;
    
    if (mediaItem.localURL) {
        
        mediaURL = mediaItem.localURL;
        mediaInfo.actualVideoUrlType = CTVideoViewVideoUrlTypeNative;
    }
    else if (mediaItem.remoteURL) {
        
        mediaURL = mediaItem.remoteURL;
        mediaInfo.actualVideoUrlType = CTVideoViewVideoUrlTypeRemote;
    }
    
    NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:mediaURL options:options];
    
    mediaInfo.asset = asset;
    return mediaInfo;
}

- (void)prepareWithCompletion:(void(^)(NSError *error))completionBLock {
    
    if (self.completion) {
        self.completion = nil;
    }
    self.completion = [completionBLock copy];
    
    NSArray *requestedKeys = @[@"playable", @"tracks", @"duration"];
    
    /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
    [self.asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
     ^{
         dispatch_async(dispatch_get_main_queue(), ^{
             
             [self prepareToPlayAsset:self.asset withKeys:requestedKeys];
         });
     }];
}

- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    /* Make sure that the value of each key has loaded successfully. */
    for (NSString *thisKey in requestedKeys)
    {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed)
        {
            if (self.completion)
            {
                self.completion(error);
            }
            
        }
        /* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
    }
    
    NSError *error;
    
    if ([asset statusOfValueForKey:@"duration" error:&error] == AVKeyValueStatusLoaded) {
        if (self.durationObserver) {
            self.durationObserver(CMTimeGetSeconds(asset.duration));
        }
        self.duration = CMTimeGetSeconds(asset.duration);
    }
    
    
    CGFloat videoWidth = [[[asset tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize].width;
    CGFloat videoHeight = [[[asset tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize].height;
    
    if (self.sizeObserver) {
        self.sizeObserver(CGSizeMake(videoWidth, videoHeight));
    }
    self.mediaSize = CGSizeMake(videoWidth, videoHeight);
    
    self.isReady = asset.isPlayable;
    
    if (self.completion) {
        self.completion(nil);
    }
}

- (void)asynchronouslyLoadURLAsset:(AVAsset *)asset
{
    
    __weak __typeof__(self) weakSelf = self;
    
    [self.asset loadValuesAsynchronouslyForKeys:@[@"tracks", @"duration", @"playable"] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            __typeof__(self) strongSelf = weakSelf;
            NSError *error;
            if ([asset statusOfValueForKey:@"duration" error:&error] == AVKeyValueStatusFailed) {
                
            }
            
            CGFloat videoWidth = [[[asset tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize].width;
            CGFloat videoHeight = [[[asset tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize].height;
            
            if (self.sizeObserver) {
                self.sizeObserver(CGSizeMake(videoWidth, videoHeight));
            }
            
            strongSelf.isVideoUrlChanged = NO;
            if (asset != strongSelf.asset) {
                return;
            }
            
            error = nil;
            if ([asset statusOfValueForKey:@"tracks" error:&error] == AVKeyValueStatusFailed) {
                strongSelf.prepareStatus = CTVideoViewPrepareStatusPrepareFailed;
                
                if ([strongSelf.operationDelegate respondsToSelector:@selector(videoViewDidFailPrepareWithError:)]) {
                    [strongSelf.operationDelegate videoViewDidFailPrepareWithError:error];
                }
                return;
            }
            
            
            if ([strongSelf.operationDelegate respondsToSelector:@selector(videoViewDidFinishPrepare)]) {
                [strongSelf.operationDelegate videoViewDidFinishPrepare];
            }
        });
    }];
}





#pragma mark - getters and setters
- (void)setAsset:(AVURLAsset *)asset
{
    _asset = asset;
    if (asset) {
        self.isVideoUrlChanged = YES;
        self.prepareStatus = CTVideoViewPrepareStatusNotPrepared;
        self.videoUrlType = CTVideoViewVideoUrlTypeAsset;
        self.actualVideoUrlType = CTVideoViewVideoUrlTypeAsset;
    }
}


@end
