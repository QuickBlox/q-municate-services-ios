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

- (void)mediaInfoForItem:(QMMediaItem *)mediaItem completion:(void(^)(QMMediaInfo *mediaInfo, NSError *error))completion;
- (void)isReadyToPlay:(QMMediaItem *)mediaItem completion:(void(^)(BOOL))completion;

- (void)thumbnailImageForMedia:(QMMediaItem *)mediaItem completion:(void (^)(UIImage *))completion;
- (void)thumbnailForMediaWithURL:(NSURL *)url completion:(void(^)(UIImage *))completion;

@end
