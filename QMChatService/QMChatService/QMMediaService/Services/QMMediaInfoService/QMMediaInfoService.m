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
#import "QMImageOperation.h"


@interface QMMediaInfoService()

@property (strong, nonatomic) NSMutableDictionary *imagesMemoryStorage;

@property (strong, nonatomic) NSMutableDictionary *mediaInfoMemoryStorage;
@property (strong, nonatomic) NSMutableDictionary *imagesInProcess;
@property (strong, nonatomic) NSOperationQueue *imagesOperationQueue;

@end

@implementation QMMediaInfoService

//MARK: - NSObject

- (instancetype)init {
    
    if (self = [super init]) {
        _mediaInfoMemoryStorage = [NSMutableDictionary dictionary];
        _imagesOperationQueue = [[NSOperationQueue alloc] init];
        _imagesOperationQueue.maxConcurrentOperationCount  = 3;
    }
    
    return self;
}

- (void)saveThumbnailImage:(UIImage *)thumbnailImage forMediaItem:(QMMediaItem *)mediaItem {
    
    NSString *imageKey = mediaItem.mediaID;
    
    if (imageKey.length > 0 && thumbnailImage) {
        self.imagesMemoryStorage[imageKey] = thumbnailImage;
        [self saveData:UIImagePNGRepresentation(thumbnailImage)
                forKey:imageKey
                 error:nil];
    }
}

- (QMMediaInfo *)cachedMediaInfoForItem:(QMMediaItem *)mediaItem {
    
    QMMediaInfo *mediaInfo = self.mediaInfoMemoryStorage[mediaItem.mediaID];
    return mediaInfo;
}


- (void)videoThumbnailForAttachment:(QBChatAttachment *)attachment completion:(void(^)(UIImage *image, NSError *error))completion {
    
    NSString *key = attachment.ID;
    if (key == nil) {
        return;
    }
    
    for (QMImageOperation *op in [self.imagesOperationQueue operations]) {
        if ([op.attachment.ID isEqualToString:key]) {
            [op cancel];
        }
    }

    
    QMImageOperation *imageOperation = [[QMImageOperation alloc] initWithAttachment:attachment
                                                                  completionHandler:^(UIImage * _Nullable image, NSError * _Nullable error) {
                                                                      if (completion) {
                                                                          completion(image, error);
                                                                      }
                                                                  }];
    [self.imagesOperationQueue addOperation:imageOperation];
}


- (void)thumbnailImageForMedia:(QBChatAttachment *)attachment completion:(void(^)(UIImage *image, NSError *error))completion {
    NSString *imageKey = attachment.ID;
    
    if (self.imagesMemoryStorage[imageKey]) {
        UIImage *image = self.imagesMemoryStorage[imageKey];
        completion(image, nil);
        return;
    }
    else {
      
        
        [self localThumbnailForAttachment:attachment
                               completion:^(UIImage *image) {
                                   //            if (!image) {
                                   //                __strong typeof(weakSelf) strongSelf = weakSelf;
                                   //                for (QMImageOperation *op in [strongSelf.imagesOperationQueue operations]) {
                                   //                    if ([op.mediaItem.mediaID isEqualToString:attachment.ID]) {
                                   //                        [op cancel];
                                   //                    }
                                   //                }
                                   //
                                   //                QMImageOperation *imageOperation = [[QMImageOperation alloc] initWithMediaItem:mediaItem completionHandler:^(UIImage * _Nullable image, NSError * _Nullable error) {
                                   //                        if (completion) {
                                   //                            [strongSelf saveThumbnailImage:image forMediaItem:mediaItem];
                                   //                            completion(image, error);
                                   //                        }
                                   //                }];
                                   //
                                   //                [strongSelf.imagesOperationQueue addOperation:imageOperation];
                                   //                NSLog(@"operations count = %d", [strongSelf.imagesOperationQueue operationCount]);
                                   //            }
                                   //            else {
                                   if (image) {
                                       self.imagesMemoryStorage[attachment.ID] = image;
                                   }
                                   completion(image, nil);
                               }];
    }
}

- (void)mediaInfoForItem:(QMMediaItem *)mediaItem completion:(void(^)(NSTimeInterval duration, CGSize size, UIImage *image, NSError *error))completion {
    
    NSString *mediaID = mediaItem.mediaID;
    
    if (mediaID.length == 0) {
        
        QMMediaInfo *localMediaInfo = [QMMediaInfo infoFromAttachment:nil];
        [localMediaInfo prepareWithCompletion:^(NSTimeInterval duration, CGSize mediaSize, UIImage *image, NSError *error) {
            if (completion) {
                completion(duration, mediaSize, image, error);
            }
        }];
        return;
    }
    
    [self cancelInfoOperationForKey:mediaID];
    //
    //    if (mediaItem.image == nil) {
    //        __weak typeof(self) weakSelf = self;
    //
    //        [self localThumbnailForMediaItem:mediaItem completion:^(UIImage *image) {
    //            mediaItem.image = image;
    //            __strong typeof(weakSelf) strongSelf = weakSelf;
    //            QMMediaInfo *mediaInfo = [QMMediaInfo infoFromMediaItem:mediaItem];
    //            [[[strongSelf class] mediaInfoOperations] setObject:mediaInfo forKey:mediaID];
    //
    //            [mediaInfo prepareWithCompletion:^(NSTimeInterval duration, CGSize mediaSize, UIImage *image, NSError *error) {
    //                if (!error) {
    //                    strongSelf.mediaInfoMemoryStorage[mediaItem.mediaID] = mediaInfo;
    //                }
    //                if (completion) {
    //                    if (image) {
    //                        [strongSelf saveThumbnailImage:image forMediaItem:mediaItem];
    //                    }
    //                    [[[self class] mediaInfoOperations] removeObjectForKey:mediaID];
    //                    completion(duration, mediaSize, image, error);
    //                }
    //            }];
    //
    //        }];
    //    }
}

- (void)localThumbnailForAttachment:(QBChatAttachment *)attachment
                         completion:(void(^)(UIImage *image))completion {
    
    
    if (attachment.ID == nil) {
        completion(nil);
        return;
    }
    if (self.imagesMemoryStorage[attachment.ID] != nil) {
        
        if (completion) {
            completion(self.imagesMemoryStorage[attachment.ID]);
        }
        return;
    }
    
    // checking attachment in cache
    NSString *path = thumbnailPath(attachment.ID);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            NSError *error;
            NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:&error];
            UIImage *image = [UIImage imageWithData:data];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (image != nil) {
                    self.imagesMemoryStorage[attachment.ID] = image;
                }
                if (completion) {
                    completion(image);
                }
            });
        });
    }
    else {
        if (completion) {
            completion(nil);
        }
    }
}

- (void)cancellAllInfoOperations {
    
    NSEnumerator *enumerator = [[[self class] mediaInfoOperations] keyEnumerator];
    
    NSString *mediaID = nil;
    
    while (mediaID = [enumerator nextObject]) {
        
        QMMediaInfo *mediaInfo = [[[self class] mediaInfoOperations] objectForKey:mediaID];
        [mediaInfo cancel];
    }
}


- (void)cancelInfoOperationForKey:(NSString *)key {
    
    [QMImageOperation cancelOperationWithID:key queue:self.imagesOperationQueue];
}

static NSString *thumbnailCacheDir() {
    
    static NSString *thumbnailCacheDir;
    
    if (!thumbnailCacheDir) {
        
        NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        thumbnailCacheDir = [cacheDir stringByAppendingPathComponent:@"Thumbnails"];
        
        static dispatch_once_t onceToken;
        
        dispatch_once(&onceToken, ^{
            if (![[NSFileManager defaultManager] fileExistsAtPath:thumbnailCacheDir]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:thumbnailCacheDir withIntermediateDirectories:NO attributes:nil error:nil];
            }
        });
    }
    
    return thumbnailCacheDir;
}


static NSString* thumbnailPath(NSString *key) {
    
    return [thumbnailCacheDir() stringByAppendingPathComponent:[NSString stringWithFormat:@"thumbnail-%@", key]];
}


- (BOOL)saveData:(NSData *)mediaData
          forKey:(NSString *)key
           error:(NSError **)errorPtr {
    
    BOOL isSucceed = [mediaData writeToFile:thumbnailPath(key)
                                    options:NSDataWritingAtomic
                                      error:errorPtr];
    return isSucceed;
}

+ (NSMutableDictionary *)mediaInfoOperations {
    
    static NSMutableDictionary *mediaInfoOperations = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        mediaInfoOperations = [NSMutableDictionary dictionary];
    });
    NSLog(@"mediaInfoOperations = %lu",(unsigned long)mediaInfoOperations.count);
    return mediaInfoOperations;
}
@end
