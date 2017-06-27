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
        
        operation.operationID = operationID;
        [queue addAsynchronousOperation:operation];
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
    if ([self isCancelled]) {
        self.finished = YES;
        return;
    }
    
    self.executing = YES;
    
    [self main];
}

- (void)main {
    
    if (self.operationBlock) {
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
