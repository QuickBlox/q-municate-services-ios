//
//  QBChatAttachment+QMMediaItem.m
//  Pods
//
//  Created by Vitaliy Gurkovsky on 2/28/17.
//
//

#import "QBChatAttachment+QMMediaItem.h"
#import "QBChatAttachment+QMCustomData.h"

@implementation QBChatAttachment (QMMediaItem)

- (void)updateWithMediaItem:(QMMediaItem *)mediaItem {
    
    self.type = [mediaItem stringContentType];
    
    NSDictionary *metaInfo = [mediaItem metaData];
    
    if (metaInfo != nil) {
        
        for (NSString *key in metaInfo.allKeys) {
            self.context[key] = metaInfo[key];
        }

        [self synchronize];
    }
}



@end
