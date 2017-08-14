//
//  QMAttachmentAssetService.h
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 2/22/17.
//
//

#import <Foundation/Foundation.h>
#import "QMAssetLoader.h"
#import "QMMediaBlocks.h"
#import "QMCancellableService.h"

@interface QMAttachmentAssetService : NSObject <QMCancellableService>

- (void)loadAssetForAttachment:(QBChatAttachment *)attachment
                     messageID:(NSString *)messageID
                    completion:(QMMediaInfoServiceCompletionBlock)completion;
@end

