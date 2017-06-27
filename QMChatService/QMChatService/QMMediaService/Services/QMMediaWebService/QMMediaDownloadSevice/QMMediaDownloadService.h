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

@interface QMMediaDownloadService : NSObject <QMCancellableService>

- (void)downloadDataForAttachment:(QBChatAttachment *)attachment
                        messageID:(NSString *)messageID
              withCompletionBlock:(QMAttachmentDataCompletionBlock)completionBlock
                    progressBlock:(QMMediaProgressBlock)progressBlock
                     cancellBlock:(QMAttachmentDownloadCancellBlock)cancellBlock;

@end
