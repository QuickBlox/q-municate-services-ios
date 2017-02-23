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

@end
@implementation QMMediaInfoService

- (void)thumbnailImageForMediaItem:(QMMediaItem *)mediaItem completion:(void (^)(UIImage *))completion {

    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:mediaItem.localURL options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    generator.appliesPreferredTrackTransform = YES;
    
    CMTime time = [asset duration];
    time.value = 0;
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime __unused requestedTime, CGImageRef im, CMTime __unused actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result != AVAssetImageGeneratorSucceeded) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (completion) {
                    completion(nil);
                }
            });
        }
        else {
            
            UIImage *image = [UIImage imageWithCGImage:im];
            
            if (image) {
                image = [self resizedImageFromImage:image];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(image);
                }
            });
        }
    };
    
    [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithBytes:&time objCType:@encode(CMTime)]] completionHandler:handler];
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

- (NSTimeInterval)durationForItem:(QMMediaItem *)mediaItem {
    
    NSAssert(mediaItem.localURL, @"media item should have local URL");
    
    NSTimeInterval duration = 0;
    
    if (mediaItem.contentType == QMMediaContentTypeAudio || mediaItem.contentType == QMMediaContentTypeVideo) {
        
        NSURL *assetURL = mediaItem.localURL;
        
        AVAsset *asset = [[AVURLAsset alloc] initWithURL:assetURL options:nil];
        duration = CMTimeGetSeconds(asset.duration);
    }
    
    return duration;
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
