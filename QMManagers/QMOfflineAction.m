//
//  QMOfflineAction.m
//  QMServices
//
//  Created by Vitaliy on 4/27/16.
//
//

#import "QMOfflineAction.h"
#import <Bolts/Bolts.h>

@interface QMOfflineAction()

@property (nonatomic,strong) BFTaskCompletionSource * source;

@end

@implementation QMOfflineAction

- (instancetype)initWithSource:(BFTaskCompletionSource*)source {
    
    if (self = [super init]) {
        _source = source;
    }
    return self;
}

- (void)performAction {
    
    if (!self.source.task.isCompleted) {
        [self.source setResult:@"YES"];
    }
}

- (void)cancelAction {
    if (!self.source.task.isCompleted) {
        [self.source cancel];
    }
}
@end
