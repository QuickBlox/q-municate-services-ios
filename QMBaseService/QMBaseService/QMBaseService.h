//
//  QMBaseService.h
//  QMServices
//
//  Created by Andrey Ivanov on 04.08.14.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMMemoryStorageProtocol.h"
#import "QMServiceManagerProtocol.h"
#import "QMOfflineManager.h"

@interface QMBaseService : NSObject <QMMemoryStorageProtocol>

/**
 *  Service manager reference.
 */
@property (weak, nonatomic, readonly, QB_NULLABLE) id <QMServiceManagerProtocol> serviceManager;

- (QB_NULLABLE id)init __attribute__((unavailable("init is not a supported initializer for this class.")));

- (QB_NULLABLE instancetype)initWithServiceManager:(QB_NONNULL id<QMServiceManagerProtocol>)serviceManager;

@property (strong, nonatomic, readonly) QMOfflineManager * offlineManager;

/**
 *  Called when the servise is will begin start
 */
- (void)serviceWillStart;

@end
