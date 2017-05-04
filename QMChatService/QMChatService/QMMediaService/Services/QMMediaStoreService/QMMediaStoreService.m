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
#import "QMAttachmentsMemoryStorage.h"
#import "QBChatAttachment+QMCustomParameters.h"


#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface QMMediaStoreService()

@property (strong, nonatomic) NSMutableDictionary *imagesMemoryStorage;
@property (strong, nonatomic) QMAttachmentsMemoryStorage *attachmentsMemoryStorage;

@end

@implementation QMMediaStoreService

- (void)dealloc {
    
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        _imagesMemoryStorage = [NSMutableDictionary dictionary];
        _attachmentsMemoryStorage = [[QMAttachmentsMemoryStorage alloc] init];
    }
    
    return self;
}


//MARK: - QMMediaStoreServiceDelegate

- (void)localImageForAttachment:(QBChatAttachment *)attachment
                      messageID:(NSString *)messageID
                       dialogID:(NSString *)dialogID
                     completion:(nonnull void (^)(UIImage * _Nonnull))completion {
    
    if (self.imagesMemoryStorage[attachment.ID] != nil) {
        
        if (completion) {
            completion(self.imagesMemoryStorage[attachment.ID]);
        }
        return;
    }
    
    // checking attachment in cache
    NSString *path = mediaPath(attachment, dialogID, messageID);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSError *error;
            NSData *data = [NSData dataWithContentsOfFile:path
                                                  options:NSDataReadingMappedIfSafe
                                                    error:&error];
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

- (QBChatAttachment *)cachedAttachmentWithID:(NSString *)attachmentID
                                forMessageID:(NSString *)messageID {
    
    return [self.attachmentsMemoryStorage attachmentWithID:attachmentID
                                             fromMessageID:messageID];
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
    
    if (cacheType & QMAttachmentCacheTypeMemory) {
        
        [self.attachmentsMemoryStorage addAttachment:attachment
                                        forMessageID:messageID];
    }
    if (cacheType & QMAttachmentCacheTypeDisc) {
        
        NSError *error = nil;
        BOOL isSucceed = [data writeToFile:mediaPath(attachment, dialogID, messageID)
                                   options:NSDataWritingAtomic
                                     error:&error];
        
        
        if (isSucceed) {
            
            attachment.localURL =  [NSURL fileURLWithPath:mediaPath(attachment,
                                                                    messageID,
                                                                    dialogID)];
            
        }
    }
    
}


- (void)updateAttachment:(QBChatAttachment *)attachment forMessageID:(NSString *)messageID {
    
    [self.attachmentsMemoryStorage addAttachment:attachment
                                    forMessageID:messageID];
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


static NSString* mediaPath(QBChatAttachment *attachment, NSString *messsageID, NSString *dialogID) {
    
    NSString *dialogDirectory = [mediaCacheDir() stringByAppendingPathComponent:dialogID];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dialogDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dialogDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSString *messageDirectory = [dialogDirectory stringByAppendingPathComponent:messsageID];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:messageDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:messageDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    return [messageDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/attachment-%@.%@",
                                                            attachment.ID,
                                                            [attachment extension]]];
}

//MARK: - Helpers

- (BOOL)isSavedLocally:(QBChatAttachment *)attachment
             messageID:(NSString *)messageID
              dialogID:(NSString *)dialogID {
    // checking attachment in cache
    NSString *path = mediaPath(attachment, dialogID, messageID);
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}



@end
