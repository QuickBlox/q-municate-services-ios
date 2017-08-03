//
//  QMMediaStoreService.m
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/7/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import "QMMediaStoreService.h"
#import "QMSLog.h"

#import "QBChatAttachment+QMCustomParameters.h"

@protocol QMStoreOperationObserver <NSObject>

- (void)didStoreData:(NSData *)data forObjectWithID:(NSString *)objectID;
- (void)didRemoveData:(NSData *)data forObjectWithID:(NSString *)objectID;


@end

@interface QMStoreOperation : NSOperation


@property (weak, nonatomic) id <QMStoreOperationObserver> observer;

@end

@implementation QMStoreOperation

@end


@interface QMMediaStoreService() {
    NSFileManager *_fileManager;
}

@property (nonatomic, strong) NSMutableDictionary *imagesMemoryStorage;
@property (nonatomic, readwrite) QMAttachmentsMemoryStorage *attachmentsMemoryStorage;
@property (nonatomic, strong, nullable) dispatch_queue_t storeServiceQueue;
@property (strong, nonatomic, nonnull) NSString *diskMediaCachePath;
@end

@implementation QMMediaStoreService

//MARK: - NSObject
- (instancetype)initWithDelegate:(id <QMMediaStoreServiceDelegate>)delegate {
    
    if ([self init]) {
        
        _storeDelegate = delegate;
        _imagesMemoryStorage = [NSMutableDictionary dictionary];
        _attachmentsMemoryStorage = [[QMAttachmentsMemoryStorage alloc] init];
        _storeServiceQueue = dispatch_queue_create("QMStoreServiceQueue", DISPATCH_QUEUE_SERIAL);
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveApplicationMemoryWarningNotification:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        _diskMediaCachePath = mediaCacheDir();
        dispatch_sync(_storeServiceQueue, ^{
            _fileManager = [NSFileManager new];
        });
    }
    
    return self;
}


- (void)dealloc {
    
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}



//MARK: - QMMediaStoreServiceDelegate

- (void)attachmentWithID:(NSString *)attachmentID
               messageID:(NSString *)messageID
                dialogID:(NSString *)dialogID {
    
    if (attachmentID != nil) {
        
        [_attachmentsMemoryStorage attachmentWithID:attachmentID fromMessageID:messageID];
    }
}

- (void)cachedDataForAttachment:(QBChatAttachment *)attachment
                      messageID:(NSString *)messageID
                       dialogID:(NSString *)dialogID
                     completion:(void (^)(NSData *data, NSURL *fileURL))completion {
    
    dispatch_async(_storeServiceQueue, ^{
        
        NSString *path = mediaPath(dialogID, messageID, attachment);
        NSData *data = nil;
        
        if ([ _fileManager fileExistsAtPath:path]) {
            
            NSError *error;
            data = [NSData dataWithContentsOfFile:path
                                          options:NSDataReadingMappedIfSafe
                                            error:&error];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                NSURL *fileURL = data ? [NSURL fileURLWithPath:path] : nil;
                completion(data, fileURL);
            }
        });
    });
}

- (void)cachedImageForAttachment:(QBChatAttachment *)attachment
                       messageID:(NSString *)messageID
                        dialogID:(NSString *)dialogID
                      completion:(void (^)(UIImage *))completion {
    
    if (self.imagesMemoryStorage[messageID] != nil) {
        
        if (completion) {
            completion(self.imagesMemoryStorage[messageID]);
        }
        return;
    }
    
    [self cachedDataForAttachment:attachment messageID:messageID dialogID:dialogID completion:^(NSData *data, NSURL __unused *fileURL) {
        UIImage *image = nil;
        if (data) {
            UIImage *image = [UIImage imageWithData:data];
            self.imagesMemoryStorage[messageID] = image;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(image);
        });
    }];
    
}

- (QBChatAttachment *)cachedAttachmentWithID:(NSString *)attachmentID
                                forMessageID:(NSString *)messageID {
    
    return [self.attachmentsMemoryStorage attachmentWithID:attachmentID
                                             fromMessageID:messageID];
}

- (NSData *)dataForImage:(UIImage*)image {
    return imageData(image);
}

- (void)saveAttachment:(QBChatAttachment *)attachment
             cacheType:(QMAttachmentCacheType)cacheType
             messageID:(NSString *)messageID
              dialogID:(NSString *)dialogID
            completion:(dispatch_block_t)completion {
    
    NSAssert(attachment.ID, @"No ID");
    NSAssert(messageID, @"No ID");
    NSAssert(dialogID, @"No ID");
    
    NSData *data = nil;
    
    if (attachment.image) {
        
        data = imageData(attachment.image);
    }
    else if (attachment.localFileURL) {
        data = [NSData dataWithContentsOfURL:attachment.localFileURL];
    }
    if (data) {
        [self saveData:data
         forAttachment:attachment
             cacheType:cacheType
             messageID:messageID
              dialogID:dialogID
            completion:completion];
    }
    else {
        if (completion) {
            completion();
        }
    }
}

- (void)saveData:(NSData *)data
   forAttachment:(QBChatAttachment *)attachment
       cacheType:(QMAttachmentCacheType)cacheType
       messageID:(NSString *)messageID
        dialogID:(NSString *)dialogID
      completion:(dispatch_block_t)completion {
    
    NSAssert(attachment.ID, @"No ID");
    NSAssert(messageID, @"No ID");
    NSAssert(dialogID, @"No ID");
    NSAssert(data.length, @"No data");
    
    dispatch_block_t saveToCacheBlock = ^{
        
        if (cacheType & QMAttachmentCacheTypeMemory) {
            
            [self.attachmentsMemoryStorage addAttachment:attachment
                                            forMessageID:messageID];
            
            [self updateAttachment:attachment
                         messageID:messageID
                          dialogID:dialogID];
            
        }
    };
    
    if (cacheType & QMAttachmentCacheTypeDisc) {
        
        dispatch_async(self.storeServiceQueue, ^{
            NSString *tempPathToFile = [attachment.localFileURL absoluteString];
            
            NSString *pathToFile = mediaPath(dialogID,
                                             messageID,
                                             attachment);
            
            if (![_fileManager fileExistsAtPath:[pathToFile stringByDeletingLastPathComponent]]) {
                [_fileManager createDirectoryAtPath:[pathToFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
            }
            NSLog(@"CREATE FILE AT PATH %@", pathToFile);
            if  (![_fileManager createFileAtPath:pathToFile contents:data attributes:nil]) {
                
                NSLog(@"Error was code: %d - message: %s", errno, strerror(errno));
                
            }
            
            attachment.localFileURL = [NSURL fileURLWithPath:pathToFile];
            dispatch_async(dispatch_get_main_queue(), ^{
                saveToCacheBlock();
                if (completion) {
                    completion();
                }
            });
        });
    }
    else {
        saveToCacheBlock();
        if (completion) {
            completion();
        }
    }
}



//MARK: - Removing

- (void)clearCacheForType:(QMAttachmentCacheType)cacheType completion:(dispatch_block_t)completion {
    
    dispatch_block_t clearMemoryBlock = ^{
        
        if (cacheType & QMAttachmentCacheTypeMemory) {
            
            [self.attachmentsMemoryStorage free];
            [self.imagesMemoryStorage removeAllObjects];
        }
    };
    
    if (cacheType & QMAttachmentCacheTypeDisc) {
        
        dispatch_async(self.storeServiceQueue, ^{
            
            [_fileManager removeItemAtPath:self.diskMediaCachePath error:nil];
            [_fileManager createDirectoryAtPath:self.diskMediaCachePath
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:NULL];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                clearMemoryBlock();
                if (completion) {
                    completion();
                }
            });
        });
    }
    else {
        clearMemoryBlock();
        if (completion) {
            completion();
        }
    }
}

- (void)clearCacheForDialogWithID:(NSString *)dialogID
                        cacheType:(QMAttachmentCacheType)cacheType
                       completion:(nullable dispatch_block_t)completion {
    
    dispatch_async(self.storeServiceQueue, ^{
        
        NSString *dialogPath = [_diskMediaCachePath stringByAppendingPathComponent:dialogID];
        [_fileManager removeItemAtPath:dialogPath
                                 error:nil];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

- (void)clearCacheForMessagesWithIDs:(NSArray <NSString *> *)messagesIDs
                            dialogID:(NSString *)dialogID
                           cacheType:(QMAttachmentCacheType)cacheType
                          completion:(nullable dispatch_block_t)completion {
    
    dispatch_async(self.storeServiceQueue, ^{
        
        NSString *dialogPath = [_diskMediaCachePath stringByAppendingPathComponent:dialogID];
        
        for (NSString *messageID in messagesIDs) {
            
            NSString *messagePath = [dialogPath stringByAppendingPathComponent:messageID];
            [_fileManager removeItemAtPath:messagePath
                                     error:nil];
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

- (void)clearCacheForMessageWithID:(NSString *)messageID
                          dialogID:(NSString *)dialogID
                         cacheType:(QMAttachmentCacheType)cacheType
                        completion:(nullable dispatch_block_t)completion {
    
    [self clearCacheForMessagesWithIDs:@[messageID]
                              dialogID:dialogID
                             cacheType:cacheType
                            completion:completion];
}

//MARK: - Helpers

static NSString* mediaCacheDir() {
    
    static NSString *mediaCacheDirString;
    
    if (!mediaCacheDirString) {
        
        NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        mediaCacheDirString = [cacheDir stringByAppendingPathComponent:@"Attachments"];
        
        static dispatch_once_t onceToken;
        
        dispatch_once(&onceToken, ^{
            if (![[NSFileManager defaultManager] fileExistsAtPath:mediaCacheDirString]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:mediaCacheDirString withIntermediateDirectories:NO attributes:nil error:nil];
            }
        });
    }
    
    return mediaCacheDirString;
}


static NSString* mediaPath(NSString *dialogID, NSString *messsageID, QBChatAttachment *attachment)   {
    
    NSString *mediaPatch =
    [[mediaCacheDir() stringByAppendingPathComponent:dialogID]
     stringByAppendingPathComponent:messsageID];
    
    NSString *filePath =
    [NSString stringWithFormat:@"/attachment-%@.%@",
     messsageID,
     [attachment extension]];
    
    return [mediaPatch stringByAppendingPathComponent:filePath];
}

//MARK: - Helpers
- (NSURL *)fileURLForAttachment:(QBChatAttachment *)attachment
                      messageID:(NSString *)messageID
                       dialogID:(NSString *)dialogID {
    // checking attachment in cache
    
    __block NSURL *fileURL = nil;
    dispatch_sync(self.storeServiceQueue, ^{
        NSString *path = mediaPath(dialogID, messageID, attachment);
        if ([_fileManager fileExistsAtPath:path]) {
            fileURL = [NSURL fileURLWithPath:path];
        }
    });
    return fileURL;
}

- (QMStoreOperation *)cachedAttachment:(QBChatAttachment *)attachment
                             messageID:(NSString *)messageID
                              dialogID:(NSString *)dialogID
                            completion:(void(^)(NSURL *filURL, NSData *data))completion {
    QMStoreOperation *operation = [QMStoreOperation new];
    
    [self cachedDataForAttachment:attachment messageID:messageID dialogID:dialogID completion:^(NSData *data, NSURL *fileURL) {
        completion(fileURL,data);
    }];
    
    return operation;
}

- (void)sizeForDialogID:(nullable NSString *)dialogID
              messageID:(nullable NSString *)messageID
           attachmentID:(nullable NSString *)attachmentID
             completion:(void (^)(float))completionBlock {
    
    completionBlock(0.0f);
}


- (void)updateAttachment:(nonnull QBChatAttachment *)attachment
               messageID:(nonnull NSString *)messageID
                dialogID:(nonnull NSString *)dialogID {
    
    [self.attachmentsMemoryStorage updateAttachment:attachment forMessageID:messageID];
    
    if ([self.storeDelegate respondsToSelector:@selector(storeService:
                                                         didUpdateAttachment:
                                                         messageID:
                                                         dialogID:)]) {
        [self.storeDelegate storeService:self
                     didUpdateAttachment:attachment
                               messageID:messageID
                                dialogID:dialogID];
    }
}

- (BOOL)nr_getAllocatedSize:(unsigned long long *)size ofDirectoryAtURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(size != NULL);
    NSParameterAssert(directoryURL != nil);
    
    // We'll sum up content size here:
    unsigned long long accumulatedSize = 0;
    
    // prefetching some properties during traversal will speed up things a bit.
    NSArray *prefetchedProperties = @[
                                      NSURLIsRegularFileKey,
                                      NSURLFileAllocatedSizeKey,
                                      NSURLTotalFileAllocatedSizeKey,
                                      ];
    
    // The error handler simply signals errors to outside code.
    __block BOOL errorDidOccur = NO;
    BOOL (^errorHandler)(NSURL *, NSError *) = ^(NSURL *url, NSError *localError) {
        if (error != NULL)
            *error = localError;
        errorDidOccur = YES;
        return NO;
    };
    
    // We have to enumerate all directory contents, including subdirectories.
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:directoryURL
                                                             includingPropertiesForKeys:prefetchedProperties
                                                                                options:(NSDirectoryEnumerationOptions)0
                                                                           errorHandler:errorHandler];
    
    // Start the traversal:
    for (NSURL *contentItemURL in enumerator) {
        
        // Bail out on errors from the errorHandler.
        if (errorDidOccur)
            return NO;
        
        // Get the type of this item, making sure we only sum up sizes of regular files.
        NSNumber *isRegularFile;
        if (! [contentItemURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:error])
            return NO;
        if (! [isRegularFile boolValue])
            continue; // Ignore anything except regular files.
        
        // To get the file's size we first try the most comprehensive value in terms of what the file may use on disk.
        // This includes metadata, compression (on file system level) and block size.
        NSNumber *fileSize;
        if (! [contentItemURL getResourceValue:&fileSize forKey:NSURLTotalFileAllocatedSizeKey error:error])
            return NO;
        
        // In case the value is unavailable we use the fallback value (excluding meta data and compression)
        // This value should always be available.
        if (fileSize == nil) {
            if (! [contentItemURL getResourceValue:&fileSize forKey:NSURLFileAllocatedSizeKey error:error])
                return NO;
            
            NSAssert(fileSize != nil, @"huh? NSURLFileAllocatedSizeKey should always return a value");
        }
        
        // We're good, add up the value.
        accumulatedSize += [fileSize unsignedLongLongValue];
    }
    
    // Bail out on errors from the errorHandler.
    if (errorDidOccur)
        return NO;
    
    // We finally got it.
    *size = accumulatedSize;
    return YES;
}

//MARK: - Helpers

static inline NSData * __nullable imageData(UIImage * __nonnull image) {
    
    int alphaInfo = CGImageGetAlphaInfo(image.CGImage);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    
    if (hasAlpha) {
        return UIImagePNGRepresentation(image);
    }
    else {
        return UIImageJPEGRepresentation(image, 1.0f);
    }
}


- (NSString *)mimeTypeForData:(NSData *)data {
    
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
            break;
        case 0x89:
            return @"image/png";
            break;
        case 0x47:
            return @"image/gif";
            break;
        case 0x49:
        case 0x4D:
            return @"image/tiff";
            break;
        case 0x25:
            return @"application/pdf";
            break;
        case 0xD0:
            return @"application/vnd";
            break;
        case 0x46:
            return @"text/plain";
            break;
        default:
            return @"application/octet-stream";
    }
    return nil;
}

//MARK: - Notifications

- (void)didReceiveApplicationMemoryWarningNotification:(NSNotification *)notification {
    
    [self.imagesMemoryStorage removeAllObjects];
}

//MARK: - QMCancellableService

- (void)cancellOperationWithID:(NSString *)operationID {
    
}

- (void)cancellAllOperations {
    
}
- (NSUInteger)getSize {
    __block NSUInteger size = 0;
    dispatch_sync(self.storeServiceQueue, ^{
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtPath:self.diskMediaCachePath];
        for (NSString *fileName in fileEnumerator) {
            NSString *filePath = [self.diskMediaCachePath stringByAppendingPathComponent:fileName];
            NSDictionary<NSString *, id> *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            size += [attrs fileSize];
        }
    });
    return size;
}
@end
