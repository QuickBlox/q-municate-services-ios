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

@property (strong, nonatomic) NSMutableDictionary *mediaInfoInProcess;
@property (strong, nonatomic) NSMutableDictionary *imagesInProcess;

@end

@implementation QMMediaInfoService

//MARK: - NSObject

- (instancetype)init {
    
    if (self = [super init]) {
        _mediaInfoInProcess = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)saveThumbnailImage:(UIImage *)thumbnailImage forMediaItem:(QMMediaItem *)mediaItem {
    
    NSString *imageKey = mediaItem.mediaID;
    
    if (imageKey.length > 0) {
        self.imagesMemoryStorage[imageKey] = thumbnailImage;
        [self saveData:UIImagePNGRepresentation(thumbnailImage)
                forKey:imageKey
                 error:nil];
    }
}

- (void)mediaInfoForItem:(QMMediaItem *)mediaItem completion:(void(^)(NSTimeInterval duration, CGSize size, UIImage *image, NSError *error))completion {
    
    NSString *mediaID = mediaItem.mediaID;
    
    if (mediaID.length == 0) {
        
        QMMediaInfo *localMediaInfo = [QMMediaInfo infoFromMediaItem:mediaItem];
        [localMediaInfo prepareWithCompletion:^(NSTimeInterval duration, CGSize mediaSize, UIImage *image, NSError *error) {
            if (completion) {
                completion(duration, mediaSize, image, error);
            }
        }];
        return;
    }
    
    [self cancelInfoOperationForKey:mediaID];
    
    if (mediaItem.image == nil) {
        __weak typeof(self) weakSelf = self;
        
        [self localThumbnailForMediaItem:mediaItem completion:^(UIImage *image) {
            mediaItem.image = image;
            __strong typeof(weakSelf) strongSelf = weakSelf;
            QMMediaInfo *mediaInfo = [QMMediaInfo infoFromMediaItem:mediaItem];
            [[[strongSelf class] mediaInfoOperations] setObject:mediaInfo forKey:mediaID];
            
            [mediaInfo prepareWithCompletion:^(NSTimeInterval duration, CGSize mediaSize, UIImage *image, NSError *error) {
                if (completion) {
                    if (image) {
                        [strongSelf saveThumbnailImage:image forMediaItem:mediaItem];
                    }
                    completion(duration, mediaSize, image, error);
                }
            }];
            
        }];
    }
}

- (void)localThumbnailForMediaItem:(QMMediaItem *)mediaItem
                    completion:(void(^)(UIImage *image))completion {
    
    NSString *mediaID = mediaItem.mediaID;
    if (mediaID == nil) {
        completion(nil);
        return;
    }
    if (self.imagesMemoryStorage[mediaItem.mediaID] != nil) {
        
        if (completion) {
            completion(self.imagesMemoryStorage[mediaID]);
        }
        return;
    }
    
    // checking attachment in cache
    NSString *path = thumbnailPath(mediaID);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
           dispatch_async(dispatch_get_main_queue(), ^{
      //  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            NSError *error;
            NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:&error];
            UIImage *image = [UIImage imageWithData:data];
            
        
                
                if (image != nil) {
                    self.imagesMemoryStorage[mediaItem.mediaID] = image;
                }
                if (completion) {
                    completion(image);
                }
      //      });
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
    
    QMMediaInfo *mediaInfo = [[[self class] mediaInfoOperations] objectForKey:key];
    if (mediaInfo) {
        [mediaInfo cancel];
    }
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

+ (NSMapTable *)mediaInfoOperations {
    
    static NSMapTable *mediaInfoOperations = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        mediaInfoOperations = [NSMapTable strongToWeakObjectsMapTable];
    });
    
    return mediaInfoOperations;
}
@end
