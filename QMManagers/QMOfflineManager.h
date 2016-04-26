//
//  QMOfflineManager.h
//  QMServices
//
//  Created by Vitaliy on 4/26/16.
//
//

#import <Foundation/Foundation.h>
#import "QMServices.h"

@interface QMOfflineManager : NSObject

+ (QB_NONNULL instancetype)instance;

- (void)performOfflineTasks;
- (void)addOfflineTask:(QB_NONNULL BFTaskCompletionSource*)source;

@end
