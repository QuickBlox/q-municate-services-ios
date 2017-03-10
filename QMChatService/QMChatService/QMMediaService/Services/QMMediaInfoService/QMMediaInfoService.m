//
//  QMMediaInfoService.m
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 2/22/17.
//
//

#import "QMMediaInfoService.h"
#import "QMMediaItem.h"
#import <AVKit/AVKit.h>


@interface QMMediaInfoService()

@property (strong, nonatomic) NSMutableDictionary *imagesMemoryStorage;
@property (strong, nonatomic) NSMutableDictionary *mediaInfoMemoryStorage;

@property (strong, nonatomic) NSMutableArray *mediaInProcess;
@property (strong, nonatomic) NSMutableArray *imagesInProcess;
@property (strong, nonatomic) dispatch_queue_t imageQueue;

@end

@implementation QMMediaInfoService

//MARK: - NSObject
- (instancetype)init {
    if (self = [super init]) {
        
        _imagesMemoryStorage = [NSMutableDictionary dictionary];
        _mediaInfoMemoryStorage = [NSMutableDictionary dictionary];
        
        _mediaInProcess = [NSMutableArray array];
        _imagesInProcess = [NSMutableArray array];
        _imageQueue = dispatch_queue_create("Image queue",DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


- (void)thumbnailForMediaWithURL:(NSURL *)url completion:(void(^)(UIImage *))completion {
    
    dispatch_async(self.imageQueue, ^{
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
        
        AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        
        CMTime time = CMTimeMake(0, 1);
        
        AVAssetImageGeneratorCompletionHandler handler = ^(CMTime __unused requestedTime, CGImageRef im, CMTime __unused actualTime, AVAssetImageGeneratorResult result, NSError *error){
            
            if (result != AVAssetImageGeneratorSucceeded) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    completion(nil);
                });
                
            }
            else {
                
                UIImage *image = [UIImage imageWithCGImage:im];
                
                UIImage *thumbnail = nil;
                
                if (image) {
                    thumbnail = [self resizedImageFromImage:image];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    completion(thumbnail);
                    
                });
                
            }
        };
        
        
        [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithBytes:&time objCType:@encode(CMTime)]]
                                        completionHandler:handler];
    });
}


- (void)thumbnailImageForMedia:(QMMediaItem *)mediaItem completion:(void (^)(UIImage *))completion {
    
    
    NSString *remoteUrlKey = [mediaItem.remoteURL.lastPathComponent stringByDeletingPathExtension];
    
    if (mediaItem.contentType != QMMediaContentTypeImage && mediaItem.contentType != QMMediaContentTypeVideo) {
        completion(nil);
    }
    
    if ([self.imagesInProcess containsObject:remoteUrlKey]) {
        return;
    }
    
    UIImage *image = self.imagesMemoryStorage[remoteUrlKey];
    
    if (image) {
        completion(image);
    }
    else {
        
        [self.imagesInProcess addObject:remoteUrlKey];
        [self thumbnailForMediaWithURL:mediaItem.remoteURL completion:^(UIImage *image) {
            [self.imagesInProcess removeObject:remoteUrlKey];
            completion(image);
        }];
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

- (void)mediaInfoForItem:(QMMediaItem *)mediaItem completion:(void(^)(QMMediaInfo *, NSError *))completion {
    
    NSString *mediaID = mediaItem.mediaID;
    
    if (mediaID.length == 0) {
        
        QMMediaInfo *localMediaInfo = [QMMediaInfo infoFromMediaItem:mediaItem];
        [localMediaInfo prepareWithCompletion:^(NSError *error) {
            
            if (completion) {
                completion(localMediaInfo,error);
            }
        }];
        
        return;
    }
    
    
    if ([self.mediaInProcess containsObject:mediaID]) {
        return;
    }
    else {
        [self.mediaInProcess addObject:mediaID];
    }
    
    QMMediaInfo *info = self.mediaInfoMemoryStorage[mediaID];
    
    if (info) {
        completion(info,nil);
    }
    else {
        
        QMMediaInfo *mediaInfo = [QMMediaInfo infoFromMediaItem:mediaItem];
        
        [mediaInfo prepareWithCompletion:^(NSError *error) {
            self.mediaInfoMemoryStorage[mediaID] = mediaInfo;
            if (completion) {
                [self.mediaInProcess removeObject:mediaID];
                completion(mediaInfo,error);
            }
        }];
    }
}

@end
