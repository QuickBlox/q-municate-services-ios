//
//  QMOfflineManager.h
//  QMServices
//
//  Created by Vitaliy on 4/26/16.
//
//

#import <Foundation/Foundation.h>
#import <Bolts/Bolts.h>
#import <Quickblox/Quickblox.h>
#import "QMOfflineAction.h"

@class  QMOfflineActionsMemoryStorage;

@protocol QMOfflineActionDelegate;

@interface QMOfflineManager : NSObject

@property (nonatomic, strong, readonly) NSArray * offlineActions;
@property (nonatomic, strong) BFCancellationTokenSource* bfTaskCancelationToken;
@property (nonatomic, strong, readonly) QMOfflineActionsMemoryStorage * offlineActionsMemoryStorage;
@property (nonatomic, weak) id <QMOfflineActionDelegate> delegate;

+ (void)setOfflineModeEnabled:(BOOL)offlineModeEnabled;
+ (BOOL)isOfflineModeEnabled;

- (QB_NONNULL BFTask*)newActionWithParameters:(QB_NULLABLE NSDictionary*)parameters;

- (void)performOfflineActions;
- (void)cleanUpOfflineQueue;

@end

@protocol QMOfflineActionDelegate <NSObject>

- (QMOfflineActionType)actionTypeForAction:(QMOfflineAction*)action;

@end