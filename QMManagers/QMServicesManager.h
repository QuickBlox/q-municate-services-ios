//
//  QBServiceManager.h
//  sample-chat
//
//  Created by Andrey Moskvin on 5/19/15.
//  Copyright (c) 2015 Igor Khomenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMServices.h"

@interface QMServicesManager : NSObject <QMServiceManagerProtocol, QMChatServiceCacheDataSource, QMChatServiceDelegate, QMChatConnectionDelegate>

+ (instancetype)instance;

- (void)logInWithUser:(QBUUser *)user completion:(void (^)(BOOL success, NSString *errorMessage))completion;
- (void)logoutWithCompletion:(void(^)())completion;

@property (nonatomic, readonly) QMAuthService* authService;
@property (nonatomic, readonly) QMChatService* chatService;

@end
