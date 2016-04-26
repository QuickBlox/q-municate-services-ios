//
//  QMOfflineManager.m
//  QMServices
//
//  Created by Vitaliy on 4/26/16.
//
//

#import "QMOfflineManager.h"

@interface QMOfflineManager()
@property (nonatomic, strong) NSMutableArray * offlineTasks;
@end

@implementation QMOfflineManager

- (instancetype)init {
    
    self = [super init];
    if (self) {
        _offlineTasks = [NSMutableArray array];
    }
    
    return self;
}

+ (QB_NONNULL instancetype)instance {
    
    static QMOfflineManager *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [[self alloc] init];
    });
    
    return manager;
}

- (void)addOfflineTask:(BFTaskCompletionSource*)source
{
    [self.offlineTasks addObject:source];
}

- (void)performOfflineTask:(BFTaskCompletionSource*)source
{
    if (!source.task.isCompleted) {
        [source setResult:@YES];
    }
    [self.offlineTasks removeObject:source];
}

- (void)performOfflineTasks {
    for (BFTaskCompletionSource * source in self.offlineTasks) {
        [self performOfflineTask:source];
    }
}
@end
