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



@interface QMMediaStoreService()

@property (strong, nonatomic) NSMutableDictionary *audioMediaMemoryStorage;
@property (strong, nonatomic) NSMutableDictionary *videoMediaMemoryStorage;
@property (strong, nonatomic) NSMutableDictionary *imageMediaMemoryStorage;

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
    }
    
    return self;
}


//MARK: - QMMediaStoreServiceDelegate

- (BOOL)isReadyToPlay:(NSString *)mediaID contentType:(NSString *)contentType {
    
    return [self mediaItemWithID:mediaID contentType:contentType].localURL.path.length > 0;
}


- (BOOL)saveMediaItem:(QMMediaItem *)mediaItem {
    
    NSAssert(mediaItem.mediaID, @"No media ID");
    
    NSData *data = [self dataForMediaItem:mediaItem];
    
    NSAssert(data.length, @"No data");
    
    BOOL sucess = [self saveData:data forMediaItem:mediaItem error:nil];
    
    if (sucess) {
        mediaItem.localURL = [NSURL fileURLWithPath:mediaPath(mediaItem.mediaID)];
        NSMutableDictionary *storage = [self storageForContentType:[mediaItem stringMediaType]];
        storage[mediaItem.mediaID] = mediaItem;
    }
    return sucess;
}


- (QMMediaItem *)mediaItemFromAttachment:(QBChatAttachment *)attachment {
    
    NSString *mediaID = attachment.ID;
    NSString *contentType = attachment.type;
    return [self mediaItemWithID:mediaID contentType:contentType];
    
}

- (QMMediaItem *)mediaItemWithID:(NSString *)mediaID contentType:(NSString *)contentType {
    
    NSMutableDictionary *storage = [self storageForContentType:contentType];
    
    QMMediaItem *item = storage[mediaID];
    
    if (!item) {
        
        NSString *path = mediaPath(mediaID);
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            
            NSURL *localURL = [NSURL fileURLWithPath:path];
            QMMediaContentType mediaContentType;
            if ([contentType isEqualToString:@"video"]) {
                mediaContentType = QMMediaContentTypeVideo;
            }
            else if ([contentType isEqualToString:@"audio"]) {
                mediaContentType = QMMediaContentTypeAudio;
            }
            item = [[QMMediaItem alloc] initWithName:@"mediaItem"
                                            localURL:localURL
                                           remoteURL:nil
                                         contentType:mediaContentType];
            storage[mediaID] = item;
        }
    }
    
    return item;
}


//MARK: - Helpers

- (NSMutableDictionary *)storageForContentType:(NSString *)contentType {
    
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


static NSString* mediaPath(NSString *mediaID) {
    
    return [mediaCacheDir() stringByAppendingPathComponent:[NSString stringWithFormat:@"media-%@", mediaID]];
}

- (BOOL)saveMediaData:(NSData *)mediaData
              mediaID:(NSString *)mediaID
                error:(NSError **)errorPtr {
    
    return [mediaData writeToFile:mediaPath(mediaID)
                          options:NSDataWritingAtomic
                            error:errorPtr];
}

- (BOOL)saveData:(NSData *)mediaData
    forMediaItem:(QMMediaItem *)mediaItem
           error:(NSError **)errorPtr {
    
    BOOL isSucceed = [mediaData writeToFile:mediaPath(mediaItem.mediaID)
                          options:NSDataWritingAtomic
                            error:errorPtr];
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
