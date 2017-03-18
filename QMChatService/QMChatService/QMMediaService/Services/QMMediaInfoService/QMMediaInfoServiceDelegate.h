//
//  QMMediaInfoServiceDelegate.h
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 2/22/17.
//
//

@class QMMediaItem;

@protocol QMMediaInfoServiceDelegate <NSObject>

- (void)mediaInfoForItem:(QMMediaItem *)mediaItem completion:(void(^)(NSTimeInterval duration, CGSize mediaSize, UIImage *image, NSError *error))completion;
- (void)saveThumbnailImage:(UIImage *)thumbnailImage forMediaItem:(QMMediaItem *)mediaItem;

- (void)cancellAllInfoOperations;
- (void)cancelInfoOperationForKey:(NSString *)key;

@end
