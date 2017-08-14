//
//  QMMediaStoreService.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/7/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMAttachmentStoreServiceDelegate.h"
#import "QMAttachmentsMemoryStorage.h"
#import "QMCancellableService.h"

typedef NS_OPTIONS(NSInteger, QMAttachmentCacheType) {
    
    QMAttachmentCacheTypeNone = 0,
    QMAttachmentCacheTypeMemory = 1 << 0,
    QMAttachmentCacheTypeDisc = 1 << 1
};

NS_ASSUME_NONNULL_BEGIN

@interface QMAttachmentStoreService : NSObject <QMCancellableService>

@property (strong, nonatomic, readonly) QMAttachmentsMemoryStorage *attachmentsMemoryStorage;

@property (nonatomic, weak, nullable) id <QMAttachmentStoreServiceDelegate> storeDelegate;

- (instancetype)initWithDelegate:(id <QMAttachmentStoreServiceDelegate>)delegate;

- (void)updateAttachment:(QBChatAttachment *)attachment
               messageID:(NSString *)messageID
                dialogID:(NSString *)dialogID;

- (void)cachedImageForAttachment:(QBChatAttachment *)item
                       messageID:(NSString *)messageID
                        dialogID:(NSString *)dialogID
                      completion:(void(^)(UIImage * _Nullable image))completion;
- (NSData *)dataForImage:(UIImage*)image;

- (NSOperation *)cachedAttachment:(QBChatAttachment *)attachment
                             messageID:(NSString *)messageID
                              dialogID:(NSString *)dialogID
                            completion:(void(^)(NSURL *filURL, NSData *data))completion;

- (void)saveData:(NSData *)data
   forAttachment:(QBChatAttachment *)attachment
       cacheType:(QMAttachmentCacheType)cacheType
       messageID:(NSString *)messageID
        dialogID:(NSString *)dialogID
completion:(nullable dispatch_block_t)completion;

- (void)saveAttachment:(QBChatAttachment *)attachment
             cacheType:(QMAttachmentCacheType)cacheType
             messageID:(NSString *)messageID
              dialogID:(NSString *)dialogID
completion:(nullable dispatch_block_t)completion;


- (NSURL *)fileURLForAttachment:(QBChatAttachment *)attachment
                      messageID:(NSString *)messageID
                       dialogID:(NSString *)dialogID;

- (nullable QBChatAttachment *)cachedAttachmentWithID:(NSString *)attachmentID
                                         forMessageID:(NSString *)messageID;

- (void)sizeForDialogID:(nullable NSString *)dialogID
              messageID:(nullable NSString *)messageID
           attachmentID:(nullable NSString *)attachmentID
             completion:(nullable void(^)(float length))completionBlock;

- (void)clearCacheForType:(QMAttachmentCacheType)cacheType
               completion:(nullable dispatch_block_t)completion;

- (void)clearCacheForDialogWithID:(NSString *)dialogID
                        cacheType:(QMAttachmentCacheType)cacheType
                       completion:(nullable dispatch_block_t)completion;

- (void)clearCacheForMessageWithID:(NSString *)messageID
                          dialogID:(NSString *)dialogID
                         cacheType:(QMAttachmentCacheType)cacheType
                        completion:(nullable dispatch_block_t)completion;

- (void)clearCacheForMessagesWithIDs:(NSArray <NSString *> *)messagesIDs
                            dialogID:(NSString *)dialogID
                           cacheType:(QMAttachmentCacheType)cacheType
                          completion:(nullable dispatch_block_t)completion;
@end

NS_ASSUME_NONNULL_END
