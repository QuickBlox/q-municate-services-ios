//
//  QMMediaInfo.h
//  Pods
//
//  Created by Vitaliy Gurkovsky on 2/26/17.
//
//

#import <Foundation/Foundation.h>

typedef void(^QMMediaDurationObserver)(NSTimeInterval timeInterval);
typedef void (^QMMediaSizeObserver)(CGSize size);

typedef NS_ENUM(NSUInteger, QMVideoItemPrepareStatus) {
    QMVideoItemPrepareStatusNotInitiated,
    QMVideoItemPrepareStatusNotPrepared,
    QMVideoItemPrepareStatusPreparing,
    QMVideoItemPrepareStatusPrepareFinished,
    QMVideoItemPrepareStatusPrepareFailed,
};

@class QMMediaItem;

@interface QMMediaInfo : NSObject

@property (copy, nonatomic) QMMediaDurationObserver durationObserver;
@property (copy, nonatomic) QMMediaSizeObserver sizeObserver;

@property (assign, nonatomic, readonly) CGSize mediaSize;
@property (assign, nonatomic, readonly) NSTimeInterval duration;

@property (strong, nonatomic, readonly) UIImage *image;
@property (nonatomic, strong, readonly) AVPlayerItem *playerItem;
@property (assign, nonatomic, readonly) QMVideoItemPrepareStatus prepareStatus;

+ (instancetype)infoFromMediaItem:(QMMediaItem *)mediaItem;
- (void)prepareWithCompletion:(void(^)(NSError *error))completionBLock;

@end
