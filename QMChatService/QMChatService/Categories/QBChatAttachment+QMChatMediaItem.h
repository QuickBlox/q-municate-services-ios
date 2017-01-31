//
//  QBChatAttachment+QMChatMediaItem.h
//  Pods
//
//  Created by Vitaliy Gurkovsky on 1/31/17.
//
//

#import <Quickblox/Quickblox.h>
#import "QMChatMediaItem.h"

@interface QBChatAttachment (QMChatMediaItem)
- (QMChatMediaItem *)toMediaItem;
@end
