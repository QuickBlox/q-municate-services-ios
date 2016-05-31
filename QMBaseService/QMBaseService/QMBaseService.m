//
//  QMBaseService.m
//  QMServices
//
//  Created by Andrey Ivanov on 04.08.14.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import "QMBaseService.h"

@interface QMBaseService() <QMOfflineActionDelegate>

@property (weak, nonatomic) id <QMServiceManagerProtocol> serviceManager;
@property (strong, nonatomic, readwrite) QMOfflineManager * offlineManager;

@end

@implementation QMBaseService

- (instancetype)initWithServiceManager:(id<QMServiceManagerProtocol>)serviceManager {
    
    self = [super init];
    if (self) {
        
        _offlineManager = [[QMOfflineManager alloc] init];
        _offlineManager.delegate = self;
        
        self.serviceManager = serviceManager;
        NSLog(@"Init - %@ service...", NSStringFromClass(self.class));
        [self serviceWillStart];
    }
    return self;
}

- (void)serviceWillStart {
    
}

#pragma mark - QMMemoryStorageProtocol

- (void)free {
    
}

@end
