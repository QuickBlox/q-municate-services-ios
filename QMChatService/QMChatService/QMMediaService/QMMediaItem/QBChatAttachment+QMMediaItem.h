//
//  QBChatAttachment+QMMediaItem.h
//  Pods
//
//  Created by Vitaliy Gurkovsky on 2/28/17.
//
//

#import <Quickblox/Quickblox.h>
#import "QMMediaItem.h"

@interface QBChatAttachment (QMMediaItem)

- (void)updateWithMediaItem:(QMMediaItem *)mediaItem;

@end
