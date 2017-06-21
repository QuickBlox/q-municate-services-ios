//
//  DRAsyncBlockOperation.h
//  DRAsyncOperations
//
//  Created by David Rodrigues on 23/04/15.
//  Copyright (c) 2015 David Rodrigues. All rights reserved.
//

#import "DRAsyncOperation.h"

@class DRAsyncBlockOperation;

/**
 Block to be executed when the async task should be considered finished.
 */
typedef void(^DRAsyncBlockOperationFinishBlock)(void);

/**
 Block which encapsulates the async task to be performed. The block should guarantee the execution of
 \c DRAsyncBlockOperationFinishBlock to mark the completion of the task and consequently finish the operation.
 
 @param finishBlock the block to execute upon completion
 */
typedef void(^DRAsyncBlockOperationExecutionBlock)(DRAsyncBlockOperationFinishBlock finishBlock);

/**
 The \c DRAsyncBlockOperation class is a subclass of \c DRAsyncOperation that executes an async task encapsulated in a 
 block.
 */
@interface DRAsyncBlockOperation : DRAsyncOperation

/**
 \c -init initializer is not available, please use the designated initializer to provide an execution block.
 */
- (instancetype)init __attribute__((unavailable("Please use `initWithBlock:` instead")));

/**
 Initializes a new \c DRAsyncBlockOperation with the provided block to be executed.
 
 @param executionBlock the block which encapsulates the async task.
 
 @return the newly-initialized \c DRAsyncBlockOperation
 */
- (instancetype)initWithBlock:(DRAsyncBlockOperationExecutionBlock)executionBlock NS_DESIGNATED_INITIALIZER;

@end

@interface DRAsyncBlockOperation (DRConvenienceInitializers)

/**
 Creates a new \c DRAsyncBlockOperation with the provided block to be executed.
 
 @param executionBlock the block which encapsulates the async task.
 
 @return the newly-initialized \c DRAsyncBlockOperation
 */
+ (instancetype)asyncBlockOperationWithBlock:(DRAsyncBlockOperationExecutionBlock)executionBlock;

@end
