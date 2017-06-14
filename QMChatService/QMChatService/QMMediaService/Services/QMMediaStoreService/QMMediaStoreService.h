//
//  QMMediaStoreService.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/7/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMMediaStoreServiceDelegate.h"

typedef NS_OPTIONS(NSInteger, QMAttachmentCacheType) {
    
    QMAttachmentCacheTypeNone = 0,
    QMAttachmentCacheTypeMemory = 1 << 0,
    QMAttachmentCacheTypeDisc = 1 << 1
};

NS_ASSUME_NONNULL_BEGIN

@interface QMMediaStoreService : NSObject

@property (nonatomic, weak, nullable) id <QMMediaStoreServiceDelegate> storeDelegate;

- (instancetype)initWithDelegate:(id <QMMediaStoreServiceDelegate>)delegate;

- (void)updateAttachment:(QBChatAttachment *)attachment
               messageID:(NSString *)messageID
                dialogID:(NSString *)dialogID;

- (void)cachedImageForAttachment:(QBChatAttachment *)item
                       messageID:(NSString *)messageID
                        dialogID:(NSString *)dialogID
                      completion:(void(^)(UIImage * _Nullable image))completion;

- (void)saveData:(NSData *)data
   forAttachment:(QBChatAttachment *)attachment
       cacheType:(QMAttachmentCacheType)cacheType
       messageID:(NSString *)messageID
        dialogID:(NSString *)dialogID;

- (void)saveAttachment:(QBChatAttachment *)attachment
             cacheType:(QMAttachmentCacheType)cacheType
             messageID:(NSString *)messageID
              dialogID:(NSString *)dialogID;

- (NSURL *)fileURLForAttachment:(QBChatAttachment *)attachment
                      messageID:(NSString *)messageID
                       dialogID:(NSString *)dialogID;

- (nullable QBChatAttachment *)cachedAttachmentWithID:(NSString *)attachmentID
                                         forMessageID:(NSString *)messageID;

- (void)sizeForDialogID:(nullable NSString *)dialogID
              messageID:(nullable NSString *)messageID
           attachmentID:(nullable NSString *)attachmentID
             completion:(nullable void(^)(float length))completionBlock;

- (void)clearCacheForType:(QMAttachmentCacheType)cacheType;

- (void)clearCacheForDialogWithID:(NSString *)dialogID
                        cacheType:(QMAttachmentCacheType)cacheType;

- (void)clearCacheForMessageWithID:(NSString *)messageID
                          dialogID:(NSString *)dialogID
                         cacheType:(QMAttachmentCacheType)cacheType;
@end

NS_ASSUME_NONNULL_END
