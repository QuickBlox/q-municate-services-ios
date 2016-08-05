//
//  QMBaseService.m
//  QMServices
//
//  Created by Andrey Ivanov on 04.08.14.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import "QMBaseService.h"

#import "QMSLog.h"


@interface QMBaseService() <QMOfflineActionDelegate>

@property (weak, nonatomic) id <QMServiceManagerProtocol> serviceManager;

@property (strong, nonatomic, readwrite) QMOfflineManager * offlineManager;

@end

@implementation QMBaseService

- (instancetype)initWithServiceManager:(id<QMServiceManagerProtocol>)serviceManager {
    
    self = [super init];
    if (self) {
        self.serviceManager = serviceManager;
        QMSLog(@"Init - %@ service...", NSStringFromClass(self.class));
        [self serviceWillStart];
    }
    return self;
}

- (void)serviceWillStart {
    
}

- (QMOfflineManager*)offlineManager {
    static QMOfflineManager *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [[QMOfflineManager alloc] init];
        [manager.multicastDelegate addDelegate:self];
    });
    
    return manager;
}

#pragma mark - QMMemoryStorageProtocol

- (void)free {
    
}

@end
