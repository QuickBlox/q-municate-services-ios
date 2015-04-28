//
//  QMBaseAuthService.h
//  Q-municate
//
//  Created by Andrey Ivanov on 29.10.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMBaseService.h"

@protocol QMAuthServiceDelegate;

@interface QMAuthService : QMBaseService

@property (assign, nonatomic, readonly) BOOL isAuthorized;

/**
 *  Add instance that confirms auth service multicaste protocol
 *
 *  @param delegate instance that confirms id<QMAuthServiceDelegate> protocol
 */
- (void)addDelegate:(id <QMAuthServiceDelegate>)delegate;

/**
 *  Remove instance that confirms auth service multicaste protocol
 *
 *  @param delegate instance that confirms id<QMAuthServiceDelegate> protocol
 */
- (void)removeDelegate:(id <QMAuthServiceDelegate>)delegate;

/**
 *  User sign up and login
 *
 *  @param user       QuickBlox User
 *  @param completion completion block
 *
 *  @return Canceble request
 */
- (QBRequest *)signUpAndLoginWithUser:(QBUUser *)user
                           completion:(void(^)(QBResponse *response,
                                               QBUUser *userProfile))completion;
/**
 *  User login
 *
 *  @param user       QuickBlox User
 *  @param completion completion block
 *
 *  @return Canceble request
 */
- (QBRequest *)logInWithUser:(QBUUser *)user
                  completion:(void(^)(QBResponse *response,
                                      QBUUser *userProfile))completion;

- (QBRequest *)logInWithFacebookSessionToken:(NSString *)sessionToken
                                  completion:(void(^)(QBResponse *response,
                                                      QBUUser *userProfile))completion;

- (QBRequest *)logOut:(void(^)(QBResponse *response))completion;

@end

@protocol QMAuthServiceDelegate <NSObject>
@optional

- (void)authServiceDidLogOut;

@end
