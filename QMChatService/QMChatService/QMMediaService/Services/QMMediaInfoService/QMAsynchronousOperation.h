//
//  QMAsynchronousOperation.h
//  Pods
//
//  Created by Vitaliy Gurkovsky on 3/23/17.
//
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

typedef  void(^QMOperationBlock)();
typedef  void(^QMCancellBlock)();

@interface QMAsynchronousOperation : NSOperation

@property (nonatomic, copy, nullable) NSString *operationID;
@property (nonatomic, copy, nullable) QMOperationBlock operationBlock;
@property (nonatomic, copy, nullable) QMCancellBlock cancellBlock;

- (void)completeOperation;

+ (instancetype)asynchronousOperationWithID:(NSString *)operationID
                                      queue:(NSOperationQueue *)queue;

@end

@interface NSOperationQueue(QMAsynchronousOperation)

- (void)cancelOperationWithID:(NSString *)operationID;
- (void)addAsynchronousOperation:(QMAsynchronousOperation *)asyncOperation;

@end

NS_ASSUME_NONNULL_END
