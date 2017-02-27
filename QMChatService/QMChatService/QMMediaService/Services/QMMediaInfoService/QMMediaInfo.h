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

@class QMMediaItem;

@interface QMMediaInfo : NSObject

@property (copy, nonatomic) QMMediaDurationObserver durationObserver;
@property (copy, nonatomic) QMMediaSizeObserver sizeObserver;

@property (assign, nonatomic, readonly) CGSize mediaSize;
@property (assign, nonatomic, readonly) NSTimeInterval duration;
@property (assign, nonatomic, readonly) BOOL isReady;
@property (assign, nonatomic, readonly) UIImage *image;

+ (instancetype)infoFromMediaItem:(QMMediaItem *)mediaItem;
- (void)prepareWithCompletion:(void(^)(NSError *error))completionBLock;

@end
