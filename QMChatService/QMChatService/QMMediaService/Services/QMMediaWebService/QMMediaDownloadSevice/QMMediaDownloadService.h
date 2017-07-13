//
//  QMMediaDownloadService.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/7/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMMediaDownloadServiceDelegate.h"
#import "QMCancellableService.h"
#import "QMMediaBlocks.h"

#import "QMAsynchronousOperation.h"


@interface QMDownloadOperation : QMAsynchronousOperation

@property (copy, nonatomic) QMAttachmentDataCompletionBlock operationCompletionBlock;

@property (nonatomic, strong) QBRequest *request;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSData *data;

@end

@interface QMMediaDownloadService : NSObject <QMCancellableService>

- (BOOL)isDownloadingMessageWithID:(NSString *)messageID;
- (QMDownloadOperation *)downloadDataForAttachment:(QBChatAttachment *)attachment
                        messageID:(NSString *)messageID
              withCompletionBlock:(QMAttachmentDataCompletionBlock)completionBlock
                    progressBlock:(QMMediaProgressBlock)progressBlock
                     cancellBlock:(QMAttachmentDownloadCancellBlock)cancellBlock;

- (void)downloadMessage:(QBChatMessage *)message
           attachmentID:(NSString *)attachmentID
          progressBlock:(QMMediaProgressBlock)progressBlock
        completionBlock:(void(^)(QMDownloadOperation *downloadOperation))completion;

@end
