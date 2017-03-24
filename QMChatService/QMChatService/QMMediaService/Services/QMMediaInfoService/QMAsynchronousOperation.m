//
//  QMAsynchronousOperation.m
//  Pods
//
//  Created by Vitaliy Gurkovsky on 3/23/17.
//
//

#import "QMAsynchronousOperation.h"

@interface QMAsynchronousOperation ()

/*
@property (nonatomic, readwrite, getter = isFinished)  BOOL finished;
@property (nonatomic, readwrite, getter = isExecuting) BOOL executing;
@property (nonatomic, strong) id<NSLocking> lock;
 */

@end

@implementation QMAsynchronousOperation
/*
@synthesize finished  = _finished;
@synthesize executing = _executing;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

- (void)start {
    if ([self isCancelled]) {
        self.finished = YES;
        return;
    }
    
    self.executing = YES;
    
    [self main];
}

- (void)completeOperation {
    if (self.executing) {
        self.executing = NO;
        self.finished = YES;
    }
}

#pragma mark - NSOperation properties

- (BOOL)isAsynchronous {
    return YES;
}

- (void)setExecuting:(BOOL)executing {
    [self.lock lock];
    
    if (_executing != executing) {
        [self willChangeValueForKey:@"isExecuting"];
        _executing = executing;
        [self didChangeValueForKey:@"isExecuting"];
    }
    
    [self.lock unlock];
}

- (void)setFinished:(BOOL)finished {
    [self.lock lock];
    
    if (self.isFinished != finished) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        [self didChangeValueForKey:@"isFinished"];
    }
    
    [self.lock unlock];
}

- (BOOL)isExecuting {
    [self.lock lock];
    BOOL value = _executing;
    [self.lock unlock];
    
    return value;
}

- (BOOL)isFinished {
    [self.lock lock];
    BOOL value = _finished;
    [self.lock unlock];
    
    return value;
}

@end

*/

/*
 We need to do old school synthesizing as the compiler has trouble creating the internal ivars.
 */
@synthesize ready = _ready;
@synthesize executing = _executing;
@synthesize finished = _finished;

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.ready = YES;
    }
    
    return self;
}

#pragma mark - State

- (void)setReady:(BOOL)ready
{
    if (_ready != ready)
    {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isReady))];
        _ready = ready;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isReady))];
    }
}

- (BOOL)isReady
{
    return _ready;
}

- (void)setExecuting:(BOOL)executing
{
    if (_executing != executing)
    {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
        _executing = executing;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    }
}

- (BOOL)isExecuting
{
    return _executing;
}

- (void)setFinished:(BOOL)finished
{
    if (_finished != finished)
    {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
        _finished = finished;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    }
}

- (BOOL)isFinished
{
    return _finished;
}

- (BOOL)isAsynchronous
{
    return YES;
}

#pragma mark - Control

- (void)start
{
    if (!self.isExecuting)
    {
        self.ready = NO;
        self.executing = YES;
        self.finished = NO;
        
        NSLog(@"\"%@\" Operation Started.", self.name);
    }
}

- (void)finish
{
    if (self.isExecuting)
    {
        NSLog(@"\"%@\" Operation Finished.", self.name);
        
        self.executing = NO;
        self.finished = YES;
    }
}

@end
