//
//  QMMediaInfoServiceDelegate.h
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 2/22/17.
//
//

@class QMMediaItem;

@protocol QMMediaInfoServiceDelegate <NSObject>

- (void)imageForMedia:(QMMediaItem *)mediaItem completion:(void(^)(UIImage *thumbnailImage))completion;
- (void)duration:(QMMediaItem *)mediaItem completion:(void(^)(NSTimeInterval duration))completion;
@end
