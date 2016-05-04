//
//  QMOfflineManager.m
//  QMServices
//
//  Created by Vitaliy on 4/26/16.
//
//

#import "QMOfflineManager.h"
#import "QMOfflineAction.h"
#import "QMOfflineActionsMemoryStorage.h"

static BOOL _QMOfflineManager_offlineModeEnabled = YES;

@interface QMOfflineManager()

@property (nonatomic, strong) NSMutableArray * mutableOfflineActions;

@end

@implementation QMOfflineManager

#pragma mark - Life Cycle
- (instancetype)init {
    
    self = [super init];
    if (self) {
        _mutableOfflineActions = [NSMutableArray array];
        _bfTaskCancelationToken = [BFCancellationTokenSource cancellationTokenSource];
        _offlineActionsMemoryStorage = [QMOfflineActionsMemoryStorage new];
    }
    
    return self;
}

- (QB_NONNULL BFTask*)newActionWithParameters:(NSDictionary*)parameters {
    
    BFTaskCompletionSource * source =  [BFTaskCompletionSource taskCompletionSource];
    
    if (![QBChat instance].isConnected && _QMOfflineManager_offlineModeEnabled) {
        
        QMOfflineAction * action = [[QMOfflineAction alloc] initWithSource:source];
        
        if  (parameters) {
            action.parameters = parameters;
        }
        if  ([self.delegate respondsToSelector:@selector(actionTypeForAction:)]) {
            action.actionType = [self.delegate actionTypeForAction:action];
            
        }
        [self addOfflineAction:action];
    }
    else {
        
        [source setResult:@"YES"];
    }

    return [source.task continueWithBlock:^id _Nullable(BFTask * _Nonnull task) {
        return nil;
    } cancellationToken:self.bfTaskCancelationToken.token];
}

+ (QB_NONNULL instancetype)instance {
    
    static QMOfflineManager *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [[self alloc] init];
    });
    
    return manager;
}

- (void)addOfflineAction:(QMOfflineAction*)action {
    [self.mutableOfflineActions addObject:action];
}

- (NSArray*)offlineActions {
    return [_mutableOfflineActions copy];
}

#pragma mark - Performing

- (void)performOfflineAction:(QMOfflineAction*)action {
    [action performAction];
    [self.mutableOfflineActions removeObject:action];
}

- (void)performOfflineActions {
    for (QMOfflineAction * action in self.offlineActions) {
        [self performOfflineAction:action];
    }
}

#pragma mark - Cancelation

- (void)cancelOfflineAction:(QMOfflineAction*)action {
    [action cancelAction];
    [self.mutableOfflineActions removeObject:action];
}

- (void)cleanUpOfflineQueue {
   [self.bfTaskCancelationToken cancel];
    
    for (QMOfflineAction * action in self.offlineActions) {
        [self cancelOfflineAction:action];
    }
   [self.mutableOfflineActions removeAllObjects];
    
    self.bfTaskCancelationToken = [BFCancellationTokenSource cancellationTokenSource];
}

#pragma mark - Offline Mode Settings

+ (void)setOfflineModeEnabled:(BOOL)offlineModeEnabled {
    _QMOfflineManager_offlineModeEnabled = offlineModeEnabled;
}

+ (BOOL)isOfflineModeEnabled {
    return _QMOfflineManager_offlineModeEnabled;
}
@end
