//
//  QMMediaInfoServiceDelegate.h
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 2/22/17.
//
//

@class QMMediaItem;
@class QMMediaInfo;

@protocol QMMediaInfoServiceDelegate <NSObject>

- (void)getMediaInfo:(QMMediaItem *)mediaItem completion:(QMMediaInfo *)mediaInfo;
- (void)isReadyToPlay:(QMMediaItem *)mediaItem completion:(void(^)(BOOL))completion;

//- (void)imageForMedia:(QMMediaItem *)mediaItem completion:(void(^)(UIImage *thumbnailImage))completion;
//- (void)duration:(QMMediaItem *)mediaItem completion:(void(^)(NSTimeInterval duration))completion;
@end
