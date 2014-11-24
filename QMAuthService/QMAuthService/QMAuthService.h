//
//  QMBaseAuthService.h
//  Q-municate
//
//  Created by Andrey Ivanov on 29.10.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMBaseService.h"

@interface QMAuthService : QMBaseService

@property (assign, nonatomic, readonly) BOOL isAuthorized;

- (void)signUpAndLoginWithUser:(QBUUser *)user
                    completion:(void(^)(QBResponse *response, QBUUser *userProfile))completion;

- (void)logInWithUser:(QBUUser *)user
           completion:(void(^)(QBResponse *response, QBUUser *userProfile))completion;

- (void)logInWithFacebookSessionToken:(NSString *)sessionToken
                           completion:(void(^)(QBResponse *response, QBUUser *userProfile))completion;

- (void)logOut:(void(^)(QBResponse *response))completion;

@end
