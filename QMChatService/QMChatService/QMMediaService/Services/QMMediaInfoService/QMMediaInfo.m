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

@property (nonatomic, strong) AVURLAsset *asset;

@property (nonatomic, assign) BOOL isVideoUrlChanged;


@property (nonatomic, strong, readwrite) NSURL *actualVideoPlayingUrl;
@property (nonatomic, assign, readwrite) QMVideoUrlType actualVideoUrlType;

@property (copy, nonatomic) void(^completion)(NSError *error);

@property (assign, nonatomic, readwrite) CGSize mediaSize;
@property (assign, nonatomic, readwrite) NSTimeInterval duration;
@property (assign, nonatomic, readwrite) BOOL isReady;
@property (assign, nonatomic, readwrite) UIImage *image;

@end



@implementation QMMediaInfo

- (void)dealloc {
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}
//MARK - NSObject
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
    
//    NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:mediaURL options:nil];
    
    mediaInfo.asset = asset;
    return mediaInfo;
}

- (void)prepareWithCompletion:(void(^)(NSError *error))completionBLock {
    
    AVURLAsset *asset = self.asset;
    NSAssert(asset != nil, @"Asset shouldn't be nill");
    
    if (self.completion) {
        self.completion = nil;
    }
    self.completion = [completionBLock copy];
    
    NSArray *requestedKeys = @[@"playable", @"tracks", @"duration"];
    
    /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
    [self.asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self prepareAsset:self.asset withKeys:requestedKeys];
        });
    }];
}

- (void)prepareAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys {
    // Make sure that the value of each key has loaded successfully.
    for (NSString *thisKey in requestedKeys) {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed) {
            if (self.completion) {
                self.completion(error);
            }
        }
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


#pragma mark - getters and setters
- (void)setAsset:(AVURLAsset *)asset
{
    _asset = asset;
    
    if (asset) {
        self.isVideoUrlChanged = YES;
        self.actualVideoUrlType = QMVideoUrlTypeAsset;
    }
}


@end
