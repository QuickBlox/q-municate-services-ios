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

@interface QMOfflineManager : NSObject

@property (nonatomic, strong, readonly)  NSArray * offlineActions;

+ (QB_NONNULL instancetype)instance;

+ (void)setOfflineModeEnabled:(BOOL)offlineModeEnabled;
+ (BOOL)isOfflineModeEnabled;

- (QB_NONNULL BFTask*)newActionWithParameters:(NSDictionary*)parameters;

- (void)performOfflineActions;
- (void)cleanUpOfflineQueue;



@end
