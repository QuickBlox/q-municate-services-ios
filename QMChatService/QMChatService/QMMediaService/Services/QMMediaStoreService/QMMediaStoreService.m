//
//  QMMediaStoreService.m
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/7/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import "QMMediaStoreService.h"
#import "QMMediaStoreServiceDelegate.h"
#import "QMMediaItem.h"
#import "QMSLog.h"

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface QMMediaStoreService()

@property (strong, nonatomic) NSMutableDictionary *audioMediaMemoryStorage;
@property (strong, nonatomic) NSMutableDictionary *videoMediaMemoryStorage;
@property (strong, nonatomic) NSMutableDictionary *imageMediaMemoryStorage;

@property (strong, nonatomic) NSMutableDictionary *imagesMemoryStorage;
@property (assign, nonatomic) BOOL isCrossplatform;
@end

@implementation QMMediaStoreService

- (void)dealloc {
    
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        _audioMediaMemoryStorage = [NSMutableDictionary dictionary];
        _videoMediaMemoryStorage = [NSMutableDictionary dictionary];
        _imageMediaMemoryStorage = [NSMutableDictionary dictionary];
        
        _imagesMemoryStorage = [NSMutableDictionary dictionary];
    }
    
    return self;
}


//MARK: - QMMediaStoreServiceDelegate

- (void)localImageFromMediaItem:(QMMediaItem *)mediaItem completion:(void(^)(UIImage *image))completion {
    
    if (self.imagesMemoryStorage[mediaItem.mediaID] != nil) {
        if (completion) {
            completion(self.imagesMemoryStorage[mediaItem.mediaID]);
        }
        return;
    }
    
    // checking attachment in cache
    NSString *path = mediaPath(mediaItem);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSError *error;
            
            NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:&error];
            
            UIImage *image = [UIImage imageWithData:data];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (image != nil) {
                    self.imagesMemoryStorage[mediaItem.mediaID] = image;
                }
                if (completion) {
                    completion(image);
                }
            });
        });
        
        return;
    }
}



- (BOOL)saveMediaItem:(QMMediaItem *)mediaItem {
    
    NSAssert(mediaItem.mediaID, @"No media ID");
    
    if (mediaItem.contentType == QMMediaContentTypeVideo) {
        
        NSMutableDictionary *storage = [self memoryStorageForContentType:[mediaItem stringContentType]];
        
        storage[mediaItem.mediaID] = mediaItem;
        
        return YES;
    }
    else {
        
        NSData *data = [self dataForMediaItem:mediaItem];
        
        NSAssert(data.length, @"No data");
        
        BOOL sucess = [self saveData:data
                        forMediaItem:mediaItem
                               error:nil];
        
        if (sucess) {
            
            mediaItem.localURL = [NSURL fileURLWithPath:mediaPath(mediaItem)];
            
            NSMutableDictionary *storage = [self memoryStorageForContentType:[mediaItem stringContentType]];
            storage[mediaItem.mediaID] = mediaItem;
        }
        
        return sucess;
    }
}

- (void)updateMediaItem:(QMMediaItem *)mediaItem {
    
    NSMutableDictionary *memoryStorage = [self memoryStorageForContentType:[mediaItem stringContentType]];
    QMMediaItem *itemToUpdate = memoryStorage[mediaItem.mediaID];
    
    if (itemToUpdate) {
        memoryStorage[mediaItem.mediaID] = mediaItem;
    }
}

- (QMMediaItem *)mediaItemFromAttachment:(QBChatAttachment *)attachment {
    
    NSString *mediaID = attachment.ID;
    NSString *contentType = attachment.type;
    
    NSMutableDictionary *storage = [self memoryStorageForContentType:contentType];
    
    QMMediaItem *mediaItem = storage[mediaID];
    
    if (mediaItem) {
        return mediaItem;
    }
    else {
        
    
         mediaItem = [QMMediaItem new];
         [mediaItem updateWithAttachment:attachment];
        NSString *path = mediaPath(mediaItem);
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
    
            NSURL *localURL = [NSURL fileURLWithPath:path];
           
            mediaItem.localURL = localURL;
            [mediaItem updateWithAttachment:attachment];
            
            NSMutableDictionary *storage = [self memoryStorageForContentType:contentType];
            storage[mediaID] = mediaItem;
            return mediaItem;
        }
        
        return nil;
    }
}

//MARK: - Helpers

- (NSMutableDictionary *)memoryStorageForContentType:(NSString *)contentType {
    
    NSAssert(contentType.length > 0, @"Should specify contetn type");
    
    NSMutableDictionary *storage = nil;
    
    if ([contentType isEqualToString:@"audio"]) {
        
        storage = _audioMediaMemoryStorage;
    }
    else if ([contentType isEqualToString:@"video"]) {
        
        storage = _videoMediaMemoryStorage;
    }
    else if ([contentType isEqualToString:@"image"]) {
        
        storage = _imageMediaMemoryStorage;
    }
    
    return storage;
}


static NSString* mediaCacheDir() {
    
    static NSString *mediaCacheDirString;
    
    if (!mediaCacheDirString) {
        
        NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        mediaCacheDirString = [cacheDir stringByAppendingPathComponent:@"Media"];
        
        static dispatch_once_t onceToken;
        
        dispatch_once(&onceToken, ^{
            if (![[NSFileManager defaultManager] fileExistsAtPath:mediaCacheDirString]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:mediaCacheDirString withIntermediateDirectories:NO attributes:nil error:nil];
            }
        });
    }
    
    return mediaCacheDirString;
}


//static NSString* mediaItemPath(NSString *mediaID, NSString *contentType) {
//
//    return [mediaCacheDir() stringByAppendingPathComponent:[NSString stringWithFormat:@"media-%@%@", mediaID,extension(contentType)]];
//}

static NSString* mediaPath(QMMediaItem *mediaItem) {
    
    return [mediaCacheDir() stringByAppendingPathComponent:[NSString stringWithFormat:@"media-%@.%@", mediaItem.mediaID, mediaItem.extension]];
}


- (BOOL)saveData:(NSData *)mediaData
    forMediaItem:(QMMediaItem *)mediaItem
           error:(NSError **)errorPtr {
    
    BOOL isSucceed = [mediaData writeToFile:mediaPath(mediaItem)
                                    options:NSDataWritingAtomic
                                      error:errorPtr];
    return isSucceed;
}

- (NSData *)dataForMediaItem:(QMMediaItem *)item {
    
    if (item.data) {
        return item.data;
    }
    
    if (item.localURL != nil) {
        NSData *data = [NSData dataWithContentsOfURL:item.localURL];
        return data;
    }
    
    return nil;
}





@end
