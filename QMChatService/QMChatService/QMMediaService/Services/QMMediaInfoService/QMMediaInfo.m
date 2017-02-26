//
//  QMMediaInfo.m
//  Pods
//
//  Created by Vitaliy Gurkovsky on 2/26/17.
//
//

#import "QMMediaInfo.h"

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



static void * kCTVideoViewKVOContext = &kCTVideoViewKVOContext;

@interface QMMediaInfo ()

@property (nonatomic, assign) BOOL isVideoUrlChanged;

@property (nonatomic, assign, readwrite) CTVideoViewPrepareStatus prepareStatus;
@property (nonatomic, assign, readwrite) CTVideoViewVideoUrlType videoUrlType;
@property (nonatomic, strong, readwrite) NSURL *actualVideoPlayingUrl;
@property (nonatomic, assign, readwrite) CTVideoViewVideoUrlType actualVideoUrlType;

@property (nonatomic, strong, readwrite) AVPlayer *player;
@property (nonatomic, strong, readwrite) AVURLAsset *asset;
@property (nonatomic, strong, readwrite) AVPlayerItem *playerItem;

@end



@implementation QMMediaInfo

NSString * const kCTVideoViewShouldPlayRemoteVideoWhenNotWifi = @"kCTVideoViewShouldPlayRemoteVideoWhenNotWifi";

NSString * const kCTVideoViewKVOKeyPathPlayerItemStatus = @"player.currentItem.status";
NSString * const kCTVideoViewKVOKeyPathPlayerItemDuration = @"player.currentItem.duration";
NSString * const kCTVideoViewKVOKeyPathLayerReadyForDisplay = @"layer.readyForDisplay";

#pragma mark - private methods
- (void)asynchronouslyLoadURLAsset:(AVAsset *)asset
{
    if ([self.operationDelegate respondsToSelector:@selector(videoViewWillStartPrepare:)]) {
        [self.operationDelegate videoViewWillStartPrepare:self];
    }
    WeakSelf;
    [asset loadValuesAsynchronouslyForKeys:@[@"tracks", @"duration", @"playable"] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            StrongSelf;
            
            strongSelf.isVideoUrlChanged = NO;
            if (asset != strongSelf.asset && asset != strongSelf.assetToPlay) {
                return;
            }
            
            NSError *error = nil;
            if ([asset statusOfValueForKey:@"tracks" error:&error] == AVKeyValueStatusFailed) {
                strongSelf.prepareStatus = CTVideoViewPrepareStatusPrepareFailed;
                [self showCoverView];
                [self showRetryButton];
                if ([strongSelf.operationDelegate respondsToSelector:@selector(videoViewDidFailPrepare:error:)]) {
                    [strongSelf.operationDelegate videoViewDidFailPrepare:strongSelf error:error];
                }
                return;
            }
            
            if (strongSelf.shouldChangeOrientationToFitVideo) {
                CGFloat videoWidth = [[[asset tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize].width;
                CGFloat videoHeight = [[[asset tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize].height;
                
                if ([asset CTVideoView_isVideoPortraint]) {
                    if (videoWidth < videoHeight) {
                        if (strongSelf.transform.b != 1 || strongSelf.transform.c != -1) {
                            strongSelf.playerLayer.transform = CATransform3DMakeRotation(90.0 / 180.0 * M_PI, 0.0, 0.0, 1.0);
                            strongSelf.playerLayer.frame = CGRectMake(0, 0, strongSelf.frame.size.height, strongSelf.frame.size.width);
                        }
                    }
                } else {
                    if (videoWidth > videoHeight) {
                        if (strongSelf.transform.b != 1 || strongSelf.transform.c != -1) {
                            strongSelf.playerLayer.transform = CATransform3DMakeRotation(90.0 / 180.0 * M_PI, 0.0, 0.0, 1.0);
                            strongSelf.playerLayer.frame = CGRectMake(0, 0, strongSelf.frame.size.height, strongSelf.frame.size.width);
                        }
                    }
                }
            }
            
            strongSelf.playerItem = [AVPlayerItem playerItemWithAsset:asset];
            strongSelf.prepareStatus = CTVideoViewPrepareStatusPrepareFinished;
            
            if (strongSelf.shouldPlayAfterPrepareFinished) {
                [strongSelf play];
            }
            
            if ([strongSelf.operationDelegate respondsToSelector:@selector(videoViewDidFinishPrepare:)]) {
                [strongSelf.operationDelegate videoViewDidFinishPrepare:strongSelf];
            }
        });
    }];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context != &kCTVideoViewKVOContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:kCTVideoViewKVOKeyPathPlayerItemStatus]) {
        NSNumber *newStatusAsNumber = change[NSKeyValueChangeNewKey];
        AVPlayerItemStatus newStatus = [newStatusAsNumber isKindOfClass:[NSNumber class]] ? newStatusAsNumber.integerValue : AVPlayerItemStatusUnknown;
        
        if (newStatus == AVPlayerItemStatusFailed) {
            DLog(@"%@", self.player.currentItem.error);
        }
    }
    
    if ([keyPath isEqualToString:kCTVideoViewKVOKeyPathPlayerItemDuration]) {
        [self durationDidLoadedWithChange:change];
    }
    
    if ([keyPath isEqualToString:kCTVideoViewKVOKeyPathLayerReadyForDisplay]) {
        if ([change[@"new"] boolValue] == YES) {
            [self setNeedsDisplay];
            if (self.prepareStatus == CTVideoViewPrepareStatusPrepareFinished) {
                if ([self.operationDelegate respondsToSelector:@selector(videoViewDidFinishPrepare:)]) {
                    [self.operationDelegate videoViewDidFinishPrepare:self];
                }
            }
        }
    }
}

#pragma mark - Notification
- (void)didReceiveAVPlayerItemDidPlayToEndTimeNotification:(NSNotification *)notification
{
    if (notification.object == self.player.currentItem) {
        if (self.shouldReplayWhenFinish) {
            [self replay];
        } else {
            [self.player seekToTime:kCMTimeZero];
            [self showPlayButton];
        }
        
        if ([self.operationDelegate respondsToSelector:@selector(videoViewDidFinishPlaying:)]) {
            [self.operationDelegate videoViewDidFinishPlaying:self];
        }
    }
}

- (void)didReceiveAVPlayerItemPlaybackStalledNotification:(NSNotification *)notification
{
    if (notification.object == self.player.currentItem) {
        if (self.stalledStrategy == CTVideoViewStalledStrategyPlay) {
            [self play];
        }
        if (self.stalledStrategy == CTVideoViewStalledStrategyDelegateCallback) {
            if ([self.operationDelegate respondsToSelector:@selector(videoViewStalledWhilePlaying:)]) {
                [self.operationDelegate videoViewStalledWhilePlaying:self];
            }
        }
    }
}

#pragma mark - getters and setters
- (void)setAssetToPlay:(AVAsset *)assetToPlay
{
    _assetToPlay = assetToPlay;
    if (assetToPlay) {
        self.isVideoUrlChanged = YES;
        self.prepareStatus = CTVideoViewPrepareStatusNotPrepared;
        self.videoUrlType = CTVideoViewVideoUrlTypeAsset;
        self.actualVideoUrlType = CTVideoViewVideoUrlTypeAsset;
    }
}


@end
