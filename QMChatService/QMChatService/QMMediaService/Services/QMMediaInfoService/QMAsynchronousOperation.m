//
//  QMAsynchronousOperation.m
//  Pods
//
//  Created by Vitaliy Gurkovsky on 3/23/17.
//
//

#import "QMAsynchronousOperation.h"

@interface QMAsynchronousOperation()
@property (nonatomic, getter = isFinished, readwrite)  BOOL finished;
@property (nonatomic, getter = isExecuting, readwrite) BOOL executing;
@end

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}
#endif

@implementation QMAsynchronousOperation

@synthesize finished  = _finished;
@synthesize executing = _executing;

//MARK: - Class methods

+ (instancetype)asynchronousOperationWithID:(NSString *)operationID
                                      queue:(NSOperationQueue *)queue {
    
    QMAsynchronousOperation *operation = [QMAsynchronousOperation operation];
    
    if (operationID.length != 0) {
        NSLog(@"_CREATE OPERATION %@", operationID);
        operation.operationID = operationID;
        [queue setSuspended:YES];
        [queue addAsynchronousOperation:operation];
        NSLog(@"_QUEUE = %@ %@",queue, queue.operations);
    }
    else {
        NSLog(@"_CREATE NO ID OPERATION %@", operationID);
    }
    
    return operation;
}
+ (instancetype)asynchronousOperationWithID:(NSString *)operationID
                             operationBlock:(QMOperationBlock)operationBlock
                                      queue:(NSOperationQueue *)queue {
    QMAsynchronousOperation *operation = [QMAsynchronousOperation operation];
    
    if (operationID.length != 0) {
        NSLog(@"_CREATE OPERATION %@", operationID);
        operation.operationID = operationID;
        operation.operationBlock = operationBlock;
        [queue addAsynchronousOperation:operation];
        NSLog(@"_QUEUE = %@ %@",queue, queue.operations);
    }
    else {
        NSLog(@"_CREATE NO ID OPERATION %@", operationID);
    }
    
    return operation;
}
    
+ (instancetype)operation {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _finished  = NO;
        _executing = NO;
    }
    return self;
}

//MARK: - Control

-(void)completeOperation {
    
    self.executing = NO;
    self.finished  = YES;
}


- (void)start {
    NSLog(@"_START %@", _operationID);
    if ([self isCancelled]) {
        NSLog(@"_isCancelled %@", _operationID);
        self.finished = YES;
        return;
    }
    
    self.executing = YES;
    
    [self main];
}

- (void)main {
    
    if (self.operationBlock) {
        NSLog(@"NO OPERATION BLOCK");
        self.operationBlock();
    }
    else {
        [self completeOperation];
    }
}

- (void)cancel {
    
    [super cancel];
    
    dispatch_main_async_safe(^{
        if (self.cancellBlock) {
            self.cancellBlock();
        }
        _cancellBlock = nil;
    });
}

//MARK: - NSOperation methods

- (BOOL)isAsynchronous {
    return YES;
}

- (BOOL)isExecuting {
    @synchronized(self) {
        return _executing;
    }
}

- (BOOL)isFinished {
    @synchronized(self) {
        return _finished;
    }
}

- (void)setExecuting:(BOOL)executing {
    if (_executing != executing) {
        [self willChangeValueForKey:@"isExecuting"];
        @synchronized(self) {
            _executing = executing;
        }
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)setFinished:(BOOL)finished {
    if (_finished != finished) {
        [self willChangeValueForKey:@"isFinished"];
        @synchronized(self) {
            _finished = finished;
        }
        [self didChangeValueForKey:@"isFinished"];
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ ID:%@",
            [super description],self.operationID];
}

@end

@implementation NSOperationQueue(QMAsynchronousOperation)

- (void)cancelOperationWithID:(NSString *)operationID {
    
    QMAsynchronousOperation *operation = [[self _asyncOperations] objectForKey:operationID];
    [operation cancel];
}

- (void)addAsynchronousOperation:(QMAsynchronousOperation *)asyncOperation {
    
    if ([[self _asyncOperations] objectForKey:asyncOperation.operationID]) {
        NSLog(@"_Return %@", asyncOperation.operationID);
        return;
    }
    [[self _asyncOperations] setObject:asyncOperation forKey:asyncOperation.operationID];
    [self addOperation:asyncOperation];
}

- (NSMapTable *)_asyncOperations {
    
    static NSMapTable *snapshotOperations = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        snapshotOperations = [NSMapTable strongToWeakObjectsMapTable];
    });
    
    return snapshotOperations;
}


@end
