//
//  QMMediaInfoServiceDelegate.h
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 2/22/17.
//
//

@class QMMediaItem;
@protocol QMMediaInfoServiceDelegate <NSObject>

- (void)thumbnailImageForMediaItem:(QMMediaItem *)mediaItem completion:(void(^)(UIImage *thumbnailImage))completion;

@end
