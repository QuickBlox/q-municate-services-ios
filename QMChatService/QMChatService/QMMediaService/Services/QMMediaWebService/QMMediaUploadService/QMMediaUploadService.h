//
//  QMMediaUploadService.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/9/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMMediaBlocks.h"

NS_ASSUME_NONNULL_BEGIN

@interface QMUploadOperation : NSBlockOperation
@property (nonatomic, strong) NSError *error;
@property (nonatomic, copy) NSString *attachmentID;
@property (copy, nonatomic) dispatch_block_t cancelBlock;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) QBRequest *request;

@end

@interface QMMediaUploadService : NSObject

- (void)uploadAttachment:(QBChatAttachment *)attachment
                                 messageID:(NSString *)messageID
                                  withData:(NSData *)data
                             progressBlock:(_Nullable QMMediaProgressBlock)progressBlock
         completionBlock:(void(^)(QMUploadOperation *downloadOperation))completion;


- (void)uploadAttachment:(QBChatAttachment *)attachment
                                 messageID:(NSString *)messageID
                               withFileURL:(NSURL *)fileURL
                                   progressBlock:(_Nullable QMMediaProgressBlock)progressBlock
                                 completionBlock:(void(^)(QMUploadOperation *downloadOperation))completion;

- (BOOL)isUplodingMessageWithID:(NSString *)messageID;

@end
NS_ASSUME_NONNULL_END
