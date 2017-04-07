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
                     completion:(void(^)(UIImage *image))completion {
    
    if (self.imagesMemoryStorage[attachment.ID] != nil) {
        
        if (completion) {
            completion(self.imagesMemoryStorage[attachment.ID]);
        }
        return;
    }
    
    // checking attachment in cache
    NSString *path = mediaPath(attachment);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
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


- (void)save:(QBChatAttachment *)attachment {
    
    NSAssert(attachment.ID, @"No ID");
    
//    if (attachment.contentType == QMAttachmentContentTypeVideo) {
//        
//        [self.attachmentsMemoryStorage addAttachment:attachment];
//    }
//    else {
    
        NSData *data  = [self dataForAttachment:attachment];
        
        NSAssert(data.length, @"No data");
        
        BOOL sucess = [self saveData:data
                       forAtatchment:attachment
                               error:nil];
        
        if (sucess) {
            attachment.localURL =  [NSURL fileURLWithPath:mediaPath(attachment)];
            [self.attachmentsMemoryStorage addAttachment:attachment];
        }
    
}


- (void)updateAttachment:(QBChatAttachment *)attachment {
    [self.attachmentsMemoryStorage addAttachment:attachment];
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


static NSString* mediaPath(QBChatAttachment *attachment) {
    
    return [mediaCacheDir() stringByAppendingPathComponent:[NSString stringWithFormat:@"attachment-%@.%@", attachment.ID, [attachment extension]]];
}

//MARK: - Helpers

- (BOOL)saveData:(NSData *)mediaData
   forAtatchment:(QBChatAttachment *)attachment
           error:(NSError **)errorPtr {
    
    BOOL isSucceed = [mediaData writeToFile:mediaPath(attachment)
                                    options:NSDataWritingAtomic
                                      error:errorPtr];
    return isSucceed;
}

- (NSData *)dataForAttachment:(QBChatAttachment *)attachment {
    
    if (attachment.mediaData != nil) {
        
        return attachment.mediaData;
    }
    
    if (attachment.localURL != nil) {
        NSData *data = [NSData dataWithContentsOfURL:attachment.localURL];
        return data;
    }
    
    return nil;
}

- (BOOL)isSavedLocally:(QBChatAttachment *)attachment {
    // checking attachment in cache
    NSString *path = mediaPath(attachment);
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}



@end
