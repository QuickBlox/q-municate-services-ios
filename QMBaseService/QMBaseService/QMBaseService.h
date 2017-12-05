//
//  QMBaseService.h
//  QMServices
//
//  Created by Andrey Ivanov on 04.08.14.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quickblox/QBMulticastDelegate.h>
#import <Bolts/Bolts.h>

#import "QMMemoryStorageProtocol.h"
#import "QMServiceManagerProtocol.h"
#import "QMCancellableService.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^QMTaskSourceBlock)(BFTaskCompletionSource * source);

BFTask *make_task(QMTaskSourceBlock b);

@interface QMBaseService : NSObject <QMMemoryStorageProtocol>

/**
 *  Service manager reference.
 */
@property (weak, nonatomic, readonly, nullable) id <QMServiceManagerProtocol> serviceManager;

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithServiceManager:(id<QMServiceManagerProtocol>)serviceManager;

/**
 *  Called when the servise is will begin start
 */
- (void)serviceWillStart;

@end

@protocol QMBFTaskErrorProtocol
- (BFTask *)errorResult:(void (^)(NSError *error))block;
@end
@interface BFTask<__covariant ResultType> (QMBaseService) <QMBFTaskErrorProtocol>


typedef void(^QMTaskBlock)(BFTask<ResultType> *t);
typedef BFTask * _Nullable( ^QMContinueTaskBlock)(void);

- (BFTask<QMBFTaskErrorProtocol> *)continueSuccess:(QMContinueTaskBlock)block;
- (BFTask<QMBFTaskErrorProtocol> *)successResult:(QMTaskBlock)block;
- (BFTask<QMBFTaskErrorProtocol> *)successComplete:(dispatch_block_t)block;
- (BFTask<QMBFTaskErrorProtocol> *)complete:(dispatch_block_t)block;

@end



NS_ASSUME_NONNULL_END
