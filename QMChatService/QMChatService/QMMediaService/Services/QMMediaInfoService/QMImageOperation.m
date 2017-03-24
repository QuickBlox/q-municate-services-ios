//
//  QMImageOperation.m
//  Pods
//
//  Created by Vitaliy Gurkovsky on 3/23/17.
//
//

#import "QMImageOperation.h"
#import "QMMediaItem.h"
#import "QMMediaInfo.h"

@interface QMImageOperation()

@property (strong, nonatomic) QMMediaInfo *mediaInfo;

@end


@implementation QMImageOperation

- (instancetype)initWithMediaItem:(QMMediaItem *)mediaItem completionHandler:(QMImageOperationCompletionBlock)completionHandler {
    
    self = [self init];
    
    if (self) {
        _mediaItem = mediaItem;
        _mediaInfo = [QMMediaInfo infoFromMediaItem:mediaItem];
        _imageOperationCompletionBlock = [completionHandler copy];
        self.name = mediaItem.mediaID;
    }
    
    return self;
}

#pragma mark - Start
- (void)dealloc {
    NSLog(@"QMImageOperation deallock");
}

- (void)start
{
    [super start];
    
    __weak typeof(self) weakSelf = self;

    [self.mediaInfo prepareWithCompletion:^(NSTimeInterval duration, CGSize size, UIImage *image, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.imageOperationCompletionBlock) {
            strongSelf.imageOperationCompletionBlock(image,error);
        }
        [strongSelf finish];
    }];
}

- (void)cancel {
    [self.mediaInfo cancel];
    self.mediaInfo = nil;
    [super cancel];
    [self finish];
}


@end
