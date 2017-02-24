//
//  QMMediaInfoService.m
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 2/22/17.
//
//

#import "QMMediaInfoService.h"
#import "QMMediaItem.h"

@interface QMMediaInfoService()

@property (strong, nonatomic) NSMutableDictionary *imagesMemoryStorage;

@property (strong, nonatomic) NSMutableArray *imagesInProcess;
@property (strong, nonatomic) NSMutableArray *durationInProcess;

@end

@implementation QMMediaInfoService

//MARK: - NSObject
- (instancetype)init {
    if (self = [super init]) {
        _imagesMemoryStorage = [NSMutableDictionary dictionary];
        _imagesInProcess = [NSMutableArray array];
        _durationInProcess = [NSMutableArray array];
    }
    return self;
}


- (void)imageForMedia:(QMMediaItem *)mediaItem completion:(void (^)(UIImage *))completion {
    if (mediaItem.contentType != QMMediaContentTypeImage && mediaItem.contentType != QMMediaContentTypeVideo) {
        completion(nil);
    }
    if ([self.imagesInProcess containsObject:mediaItem.localURL.path]) {
        return;
    }
    
    UIImage *image = self.imagesMemoryStorage[mediaItem.localURL.path];
    if (image) {
        completion(image);
    }
    else {
        [self.imagesInProcess addObject:mediaItem.localURL.path];
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:mediaItem.localURL options:nil];
        AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        
        generator.appliesPreferredTrackTransform = YES;
        
        CMTime time = [asset duration];
        time.value = 0;
        
        AVAssetImageGeneratorCompletionHandler handler = ^(CMTime __unused requestedTime, CGImageRef im, CMTime __unused actualTime, AVAssetImageGeneratorResult result, NSError *error){
            
            if (result != AVAssetImageGeneratorSucceeded) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        [self.imagesInProcess removeObject:mediaItem.localURL.path];
                        completion(nil);
                    }
                });
                
            }
            else {
                
                UIImage *image = [UIImage imageWithCGImage:im];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    UIImage *thumbnail = nil;
                    
                    if (image) {
                        thumbnail = [self resizedImageFromImage:image];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) {
                            [self.imagesInProcess removeObject:mediaItem.localURL.path];
                            self.imagesMemoryStorage[mediaItem.localURL.path] = thumbnail;
                            completion(thumbnail);
                        }
                    });
                });
            }
        };
        
        [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithBytes:&time objCType:@encode(CMTime)]] completionHandler:handler];
    }
}

- (UIImage *)resizedImageFromImage:(UIImage *)image {
    
    CGFloat largestSide = image.size.width > image.size.height ? image.size.width : image.size.height;
    CGFloat scaleCoefficient = largestSide / 560.0f;
    CGSize newSize = CGSizeMake(image.size.width / scaleCoefficient, image.size.height / scaleCoefficient);
    
    UIGraphicsBeginImageContext(newSize);
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

- (void)duration:(QMMediaItem *)mediaItem completion:(void(^)(NSTimeInterval duration))completion {
    
    NSAssert(mediaItem.localURL, @"media item should have local URL");
    
    NSTimeInterval __block duration = 0;
    
    if (mediaItem.contentType == QMMediaContentTypeAudio) {// || mediaItem.contentType == QMMediaContentTypeVideo) {
        NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey: @YES};
        NSURL *assetURL = mediaItem.localURL;
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:assetURL options:nil];
        
//      Float64 duration =  CMTimeGetSeconds(asset.duration);
//        NSLog(@"duration = %f",duration);
//                    return;
        [asset loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^{
            NSError *error;
            
            AVKeyValueStatus status = ([asset statusOfValueForKey:@"duration" error:&error]);
            if (status == AVKeyValueStatusLoaded) {
                
                
            }
            else {
                NSLog(@"error = %@",error);
            }
        }];
    }
}


- (CGSize)videoSizeForItem:(QMMediaItem *)item {
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:item.localURL options:nil];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (tracks.count) {
        AVAssetTrack *track = [tracks objectAtIndex:0];
        return track.naturalSize;
    }
    else {
        return CGSizeZero;
    }
}

@end
