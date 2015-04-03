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

- (QBRequest *)signUpAndLoginWithUser:(QBUUser *)user
                           completion:(void(^)(QBResponse *response, QBUUser *userProfile))completion;

- (QBRequest *)logInWithUser:(QBUUser *)user
                  completion:(void(^)(QBResponse *response, QBUUser *userProfile))completion;

- (QBRequest *)logInWithFacebookSessionToken:(NSString *)sessionToken
                                  completion:(void(^)(QBResponse *response, QBUUser *userProfile))completion;

- (QBRequest *)logOut:(void(^)(QBResponse *response))completion;

@end
