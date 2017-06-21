//
//  DRAsyncOperation.m
//  DRAsyncOperations
//
//  Created by David Rodrigues on 17/04/15.
//  Copyright (c) 2015 David Rodrigues. All rights reserved.
//

#import "DRAsyncOperation.h"

typedef NS_ENUM(char, DRAsyncOperationState) {
    DRAsyncOperationStateReady,
    DRAsyncOperationStateExecuting,
    DRAsyncOperationStateFinished
};

static inline NSString *DRKeyPathFromAsyncOperationState(DRAsyncOperationState state) {
    switch (state) {
        case DRAsyncOperationStateReady:        return @"isReady";
        case DRAsyncOperationStateExecuting:    return @"isExecuting";
        case DRAsyncOperationStateFinished:     return @"isFinished";
    }
}

@interface DRAsyncOperation ()

@property(nonatomic, assign) DRAsyncOperationState state;
@property(nonatomic, strong, readonly) dispatch_queue_t dispatchQueue;

@end

@implementation DRAsyncOperation


#pragma mark -
#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *identifier = [NSString stringWithFormat:@"com.qm.%@(%p)", NSStringFromClass(self.class), self];

        _dispatchQueue = dispatch_queue_create([identifier UTF8String], DISPATCH_QUEUE_SERIAL);

        dispatch_queue_set_specific(_dispatchQueue, (__bridge const void *)(_dispatchQueue),
                                    (__bridge void *)(self), NULL);
    }
    return self;
}

#pragma mark -
#pragma mark NSOperation methods

#if defined(__IPHONE_OS_VERSION_MIN_ALLOWED) && __IPHONE_OS_VERSION_MIN_ALLOWED >= __IPHONE_7_0
- (BOOL)isAsynchronous
{
    return YES;
}
#endif

#if defined(__IPHONE_OS_VERSION_MIN_ALLOWED) && __IPHONE_OS_VERSION_MIN_ALLOWED < __IPHONE_7_0
- (BOOL)isConcurrent
{
    return YES;
}
#endif

- (BOOL)isExecuting
{
    __block BOOL isExecuting;

    [self performBlockAndWait:^{
        isExecuting = self.state == DRAsyncOperationStateExecuting;
    }];

    return isExecuting;
}

- (BOOL)isFinished
{
    __block BOOL isFinished;

    [self performBlockAndWait:^{
        isFinished = self.state == DRAsyncOperationStateFinished;
    }];

    return isFinished;
}

- (void)start
{
    @autoreleasepool {

        if ([self isCancelled]) {
            [self finish];
            return;
        }

        __block BOOL isExecuting = YES;

        [self performBlockAndWait:^{

            // Ignore this call if the operation is already executing or if has finished already
            if (self.state != DRAsyncOperationStateReady) {
                isExecuting = NO;
            }
            else {
                // Signal the beginning of operation
                self.state = DRAsyncOperationStateExecuting;
            }
        }];

        if (isExecuting) {
            // Execute async task
            [self asyncTask];
        }
    }
}

#pragma mark -
#pragma mark DRAsyncOperation methods

- (void)setState:(DRAsyncOperationState)state
{
    [self performBlockAndWait:^{

        NSString *oldStateKey = DRKeyPathFromAsyncOperationState(_state);
        NSString *newStateKey = DRKeyPathFromAsyncOperationState(state);

        [self willChangeValueForKey:oldStateKey];
        [self willChangeValueForKey:newStateKey];

        _state = state;

        [self didChangeValueForKey:newStateKey];
        [self didChangeValueForKey:oldStateKey];

    }];
}

#pragma mark Protected methods

- (void)asyncTask
{
    [self finish];
}

- (void)finish
{
    [self performBlockAndWait:^{
        // Signal the completion of operation
        if (self.state != DRAsyncOperationStateFinished) {
            self.state = DRAsyncOperationStateFinished;
        }
    }];
}

- (void)cancel {
    [super cancel];
    [self finish];
}

#pragma mark - Dispatch Queue

- (void)performBlockAndWait:(dispatch_block_t)block {
    void *context = dispatch_get_specific((__bridge const void *)(self.dispatchQueue));
    BOOL runningInDispatchQueue = context == (__bridge void *)(self);

    if (runningInDispatchQueue) {
        block();
    } else {
        dispatch_sync(self.dispatchQueue, block);
    }
}

@end
