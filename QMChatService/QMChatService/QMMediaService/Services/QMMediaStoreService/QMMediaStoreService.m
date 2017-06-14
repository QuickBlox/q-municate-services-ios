//
//  QMMediaStoreService.m
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/7/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import "QMMediaStoreService.h"
#import "QMSLog.h"
#import "QMAttachmentsMemoryStorage.h"
#import "QBChatAttachment+QMCustomParameters.h"


#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface QMMediaStoreService()

@property (strong, nonatomic) NSMutableDictionary *imagesMemoryStorage;
@property (strong, nonatomic) QMAttachmentsMemoryStorage *attachmentsMemoryStorage;

@end

@implementation QMMediaStoreService

//MARK: - NSObject

- (instancetype)initWithDelegate:(id <QMMediaStoreServiceDelegate>)delegate {
    
    if ([self init]) {
        _storeDelegate = delegate;
    }
    return self;
}


- (instancetype)init {
    
    if (self = [super init]) {
        
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
    
    NSString *path = mediaPath(dialogID, messageID, attachment);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSError *error;
            NSData *data = [NSData dataWithContentsOfFile:path
                                                  options:NSDataReadingMappedIfSafe
                                                    error:&error];
            UIImage *image = [UIImage imageWithData:data];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (image != nil) {
                    self.imagesMemoryStorage[messageID] = image;
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
            attachment.status = QMAttachmentStatusPrepared;
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
    }
    
    
}


- (void)updateAttachment:(QBChatAttachment *)attachment forMessageID:(NSString *)messageID {
    
    [self.attachmentsMemoryStorage addAttachment:attachment
                                    forMessageID:messageID];
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

- (void)clearCacheForMessageWithID:(NSString *)messageID
                          dialogID:(NSString *)dialogID
                         cacheType:(QMAttachmentCacheType)cacheType {
    
    NSString *messagePath = [[mediaCacheDir() stringByAppendingPathComponent:dialogID]
                             stringByAppendingPathComponent:messageID];
    
    [[NSFileManager defaultManager] removeItemAtPath:messagePath
                                               error:nil];
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

- (void)sizeForDialogID:(nullable NSString *)dialogID messageID:(nullable NSString *)messageID attachmentID:(nullable NSString *)attachmentID completion:(nullable void (^)(float))completionBlock {
    completionBlock(0.0f);
}


- (void)updateAttachment:(nonnull QBChatAttachment *)attachment messageID:(nonnull NSString *)messageID dialogID:(nonnull NSString *)dialogID {
    
}

@end



