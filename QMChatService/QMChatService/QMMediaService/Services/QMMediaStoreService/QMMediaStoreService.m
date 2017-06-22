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

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface QMMediaStoreService()

@property (strong, nonatomic) NSMutableDictionary *imagesMemoryStorage;
@property (strong, nonatomic, readwrite) QMAttachmentsMemoryStorage *attachmentsMemoryStorage;

@end

@implementation QMMediaStoreService

//MARK: - NSObject
- (instancetype)initWithDelegate:(id <QMMediaStoreServiceDelegate>)delegate {
    
    if ([self init]) {
        
        _storeDelegate = delegate;
        _imagesMemoryStorage = [NSMutableDictionary dictionary];
        _attachmentsMemoryStorage = [[QMAttachmentsMemoryStorage alloc] init];
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
    
    if (attachmentID == nil) {
        
        [_attachmentsMemoryStorage attachmentWithID:attachmentID fromMessageID:messageID];
        
    }
    
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *path = mediaPath(dialogID, messageID, attachment);
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            
            NSError *error;
            NSData *data = [NSData dataWithContentsOfFile:path
                                                  options:NSDataReadingMappedIfSafe
                                                    error:&error];
            UIImage *image = [UIImage imageWithData:data];
            
            
            if (image != nil) {
                self.imagesMemoryStorage[messageID] = image;
            }
            
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(image);
                });
            }
            
            
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil);
            });
        }
    });
}

- (QBChatAttachment *)cachedAttachmentWithID:(NSString *)attachmentID
                                forMessageID:(NSString *)messageID {
    
    return [self.attachmentsMemoryStorage attachmentWithID:attachmentID
                                             fromMessageID:messageID];
}

- (void)saveAttachment:(QBChatAttachment *)attachment
             cacheType:(QMAttachmentCacheType)cacheType
             messageID:(NSString *)messageID
              dialogID:(NSString *)dialogID {
    
    NSAssert(attachment.ID, @"No ID");
    NSAssert(messageID, @"No ID");
    NSAssert(dialogID, @"No ID");
    
    if (cacheType & QMAttachmentCacheTypeDisc) {
        
        NSURL *tempURL = attachment.localFileURL;
        
        NSString *filePath = mediaPath(dialogID,
                                       messageID,
                                       attachment);
        BOOL isSucceed = NO;
        
        if (tempURL) {
            if (attachment.contentType != QMAttachmentContentTypeVideo) {
                isSucceed  = [[NSFileManager defaultManager] copyItemAtURL:tempURL
                                                                     toURL:[NSURL fileURLWithPath:filePath]
                                                                     error:NULL];
            }
            
            [[NSFileManager defaultManager] removeItemAtURL:tempURL
                                                      error:NULL];
        }
        
        
        if (attachment.image) {
            
            NSData *data = UIImagePNGRepresentation(attachment.image);
            
            [self saveData:data
             forAttachment:attachment
                 cacheType:cacheType
                 messageID:messageID
                  dialogID:dialogID];
        }
        
        if (isSucceed) {
            attachment.localFileURL = [NSURL fileURLWithPath:filePath];
        }
        
    }
    
    if (cacheType & QMAttachmentCacheTypeMemory) {
        if (attachment.image) {
            self.imagesMemoryStorage[messageID] = attachment.image;
        }
        [self.attachmentsMemoryStorage addAttachment:attachment
                                        forMessageID:messageID];
        
    }
}

- (void)saveData:(NSData *)data
   forAttachment:(QBChatAttachment *)attachment
       cacheType:(QMAttachmentCacheType)cacheType
       messageID:(NSString *)messageID
        dialogID:(NSString *)dialogID {
    
    NSAssert(attachment.ID, @"No ID");
    NSAssert(messageID, @"No ID");
    NSAssert(dialogID, @"No ID");
    NSAssert(data.length, @"No data");
    
    
    if (cacheType & QMAttachmentCacheTypeDisc) {
        
        NSError *error = nil;
        BOOL isSucceed = [data writeToFile:mediaPath(dialogID, messageID, attachment)
                                   options:NSDataWritingAtomic
                                     error:&error];
        
        
        if (isSucceed) {
            
            attachment.localFileURL =  [NSURL fileURLWithPath:mediaPath(dialogID,
                                                                        messageID,
                                                                        attachment)];
            
        }
    }
    if (cacheType & QMAttachmentCacheTypeMemory) {
        
        [self.attachmentsMemoryStorage addAttachment:attachment
                                        forMessageID:messageID];
        
        [self updateAttachment:attachment
                     messageID:messageID
                      dialogID:dialogID];
        
    }
}


//MARK: - Removing

- (void)clearCacheForType:(QMAttachmentCacheType)cacheType {
    
    if (cacheType & QMAttachmentCacheTypeDisc) {
        
        [[NSFileManager defaultManager] removeItemAtPath:mediaCacheDir()
                                                   error:nil];
    }
    if (cacheType & QMAttachmentCacheTypeMemory) {
        [self.attachmentsMemoryStorage free];
        [self.imagesMemoryStorage removeAllObjects];
    }
}

- (void)clearCacheForDialogWithID:(NSString *)dialogID
                        cacheType:(QMAttachmentCacheType)cacheType {
    
    NSString *dialogPath = [mediaCacheDir() stringByAppendingPathComponent:dialogID];
    [[NSFileManager defaultManager] removeItemAtPath:dialogPath
                                               error:nil];
}

- (void)clearCacheForMessagesWithIDs:(NSArray <NSString *> *)messagesIDs
                            dialogID:(NSString *)dialogID
                           cacheType:(QMAttachmentCacheType)cacheType {
    
    NSString *dialogsPath = [mediaCacheDir() stringByAppendingPathComponent:dialogID];
    
    for (NSString *messageID in messagesIDs) {
        NSString *messagePath = [dialogsPath stringByAppendingPathComponent:messageID];
        [[NSFileManager defaultManager] removeItemAtPath:messagePath
                                                   error:nil];
    }
}

- (void)clearCacheForMessageWithID:(NSString *)messageID
                          dialogID:(NSString *)dialogID
                         cacheType:(QMAttachmentCacheType)cacheType {
    
    [self clearCacheForMessagesWithIDs:@[messageID]
                              dialogID:dialogID
                             cacheType:cacheType];
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
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:mediaPatch]) {
        NSError *error = nil;
        
        [[NSFileManager defaultManager] createDirectoryAtPath:mediaPatch
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            QMSLog(@"Failed to create directory at path with error: %@", error.localizedDescription);
            return nil;
        }
    }
    
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
    NSString *path = mediaPath(dialogID, messageID, attachment);
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return [NSURL fileURLWithPath:path];
    }
    return nil;
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
    
    if ([self.storeDelegate respondsToSelector:@selector(storeStore:
                                                         didUpdateAttachment:
                                                         messageID:
                                                         dialogID:)]) {
        [self.storeDelegate storeStore:self
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

@end
