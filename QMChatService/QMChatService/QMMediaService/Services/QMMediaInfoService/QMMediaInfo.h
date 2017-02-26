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

@property (assign, nonatomic) CGSize mediaSize;
@property (assign, nonatomic) NSTimeInterval duration;
@property (assign, nonatomic) BOOL isReady;
@property (assign, nonatomic) UIImage *image;

+ (instancetype)infoFromMediaItem:(QMMediaItem *)mediaItem;
- (void)prepareWithCompletion:(void(^)(NSError *error))completionBLock;

@end
