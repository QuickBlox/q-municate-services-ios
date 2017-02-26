//
//  QMMediaInfoService.m
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 2/22/17.
//
//

#import "QMMediaInfoService.h"
#import "QMMediaItem.h"
#import "QMMediaInfo.h"

@interface QMMediaInfoService()

@property (strong, nonatomic) NSMutableDictionary *imagesMemoryStorage;
@property (strong, nonatomic) NSMutableDictionary *mediaInfoMemoryStorage;

@property (strong, nonatomic) NSMutableArray *mediaInProcess;
@property (strong, nonatomic) NSMutableArray *imagesInProcess;;
@end

@implementation QMMediaInfoService

//MARK: - NSObject
- (instancetype)init {
    if (self = [super init]) {
        
        _imagesMemoryStorage = [NSMutableDictionary dictionary];
        _mediaInfoMemoryStorage = [NSMutableDictionary dictionary];
        _mediaInProcess = [NSMutableArray array];
        _imagesInProcess = [NSMutableArray array];
        
    }
    return self;
}

- (void)isReadyToPlay:(QMMediaItem *)mediaItem completion:(void (^)(BOOL))completion {
    
}

- (void)imageForMedia:(QMMediaItem *)mediaItem completion:(void (^)(UIImage *))completion {
    if (mediaItem.contentType != QMMediaContentTypeImage && mediaItem.contentType != QMMediaContentTypeVideo) {
        completion(nil);
    }
    
    
    if ([self.imagesInProcess containsObject:mediaItem.remoteURL.path]) {
        return;
    }
    
    UIImage *image = self.imagesMemoryStorage[mediaItem.remoteURL.path];
    
    if (image) {
        completion(image);
    }
    else {
        
        [self.imagesInProcess addObject:mediaItem.remoteURL.path];
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:mediaItem.remoteURL options:nil];
        AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        
        generator.appliesPreferredTrackTransform = YES;
        
        CMTime time = [asset duration];
        time.value = 0;
        
        AVAssetImageGeneratorCompletionHandler handler = ^(CMTime __unused requestedTime, CGImageRef im, CMTime __unused actualTime, AVAssetImageGeneratorResult result, NSError *error){
            
            if (result != AVAssetImageGeneratorSucceeded) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        [self.imagesInProcess removeObject:mediaItem.remoteURL.path];
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
                            [self.imagesInProcess removeObject:mediaItem.remoteURL.path];
                            self.imagesMemoryStorage[mediaItem.remoteURL.path] = thumbnail;
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

- (void)mediaInfoForItem:(QMMediaItem *)mediaItem completion:(void(^)(QMMediaInfo *))completion {
    
    //check for cached mediaItem
    
    if (!mediaItem.mediaID) {
        
        QMMediaInfo *localMediaInfo = [QMMediaInfo infoFromMediaItem:mediaItem];
        [localMediaInfo prepareWithCompletion:^(NSError *error) {
            
            if (completion) {
                completion(localMediaInfo);
            }
        }];
        
        return;
    }

    NSString *remoteUrlKey = mediaItem.remoteURL.path;
    
    QMMediaInfo *info = self.mediaInfoMemoryStorage[remoteUrlKey];
    
    if (info) {
        completion(info);
    }
    else {
        //get media info from url asset
        NSURL *remoteURL = mediaItem.remoteURL;
    
    if (remoteURL.path.length > 0) {
        
        
        QMMediaInfo *mediaInfo = [QMMediaInfo infoFromMediaItem:mediaItem];
        [mediaInfo prepareWithCompletion:^(NSError *error) {
            
            self.mediaInfoMemoryStorage[remoteUrlKey] = mediaInfo;
            
            if (completion) {
                completion(mediaInfo);
            }
        }];
        
    }
    }
    
}


@end
