//
//  QMMediaInfoService.h
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 2/22/17.
//
//

#import <Foundation/Foundation.h>
#import "QMMediaInfoServiceDelegate.h"
#import "QMMediaInfo.h"
#import "QMMediaBlocks.h"
#import "QMCancellableService.h"

@interface QMMediaInfoService : NSObject <QMCancellableService>

- (void)mediaInfoForAttachment:(QBChatAttachment *)attachment
                     messageID:(NSString *)messageID
                    completion:(QMMediaInfoServiceCompletionBlock)completion;
@end
