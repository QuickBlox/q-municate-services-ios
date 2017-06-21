//
//  QMImageOperation.h
//  Pods
//
//  Created by Vitaliy Gurkovsky on 3/23/17.
//
//

#import <UIKit/UIKit.h>
#import "DRAsyncOperation.h"

@class QBChatAttachment;

typedef void(^QMImageOperationCompletionBlock)(UIImage * _Nullable image, Float64 durationSeconds, CGSize size, NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface QMImageOperation : DRAsyncOperation

@property (nonatomic, copy) NSString *operationID;
@property (nonatomic, copy, nullable) QMImageOperationCompletionBlock imageOperationCompletionBlock;

- (instancetype)initWithURL:(NSURL *)url
                 completionHandler:(nullable QMImageOperationCompletionBlock)completionHandler;

@end

NS_ASSUME_NONNULL_END
