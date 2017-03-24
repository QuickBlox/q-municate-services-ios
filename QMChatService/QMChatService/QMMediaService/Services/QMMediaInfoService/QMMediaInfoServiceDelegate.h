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

- (void)mediaInfoForItem:(QMMediaItem *)mediaItem completion:(void(^)(NSTimeInterval duration, CGSize mediaSize, UIImage *image, NSError *error))completion;
- (void)saveThumbnailImage:(UIImage *)thumbnailImage forMediaItem:(QMMediaItem *)mediaItem;
- (QMMediaInfo *)cachedMediaInfoForItem:(QMMediaItem *)mediaItem;
    
- (void)cancellAllInfoOperations;
- (void)cancelInfoOperationForKey:(NSString *)key;

- (void)localThumbnailForMediaItem:(QMMediaItem *)mediaItem
                        completion:(void(^)(UIImage *image))completion;
- (void)thumbnailImageForMedia:(QMMediaItem *)mediaItem completion:(void(^)(UIImage *image, NSError *error))compeltion;
@end
