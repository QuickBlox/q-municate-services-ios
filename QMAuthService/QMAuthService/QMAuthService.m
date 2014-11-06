//
//  QMBaseAuthService.m
//  Q-municate
//
//  Created by Andrey Ivanov on 29.10.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMAuthService.h"

@interface QMAuthService()

@property (assign, nonatomic) BOOL isAuthorized;

@end

@implementation QMAuthService

- (void)logOut:(void(^)(QBResponse *response))completion {
    
    __weak __typeof(self)weakSelf = self;
    [QBRequest logOutWithSuccessBlock:^(QBResponse *response) {
        
        weakSelf.isAuthorized = NO;
        
        if (completion)
            completion(response);
        
    } errorBlock:^(QBResponse *response) {
        
        [weakSelf showMessageForQBResponce:response];
        
        if (completion)
            completion(response);
    }];
}

- (void)signUpAndLoginWithUser:(QBUUser *)user
                    completion:(void(^)(QBResponse *response, QBUUser *userProfile))completion {
    
    __weak __typeof(self)weakSelf = self;
    [QBRequest signUp:user
         successBlock:^(QBResponse *response, QBUUser *newUser) {
             
             [weakSelf logInWithUser:user
                          completion:^(QBResponse *logInResponse, QBUUser *userProfile) {
                              weakSelf.isAuthorized = YES;
                          }];
             
         } errorBlock:^(QBResponse *response) {
             
             [weakSelf showMessageForQBResponce:response];
             
             if (completion)
                 completion(response, nil);
         }];
}

#pragma mark - Private methods

- (void)logInWithUser:(QBUUser *)user
           completion:(void(^)(QBResponse *response, QBUUser *userProfile))completion {
    
    void (^errorBlock)(id) = ^(QBResponse *response){
        [self showMessageForQBResponce:response];
        completion(response, nil);
    };
    
    if (user.email) {
        
        [QBRequest logInWithUserEmail:user.email
                             password:user.password
                         successBlock:completion
                           errorBlock:errorBlock];
    }
    else if (user.login) {
        
        [QBRequest logInWithUserLogin:user.login
                             password:user.password
                         successBlock:completion
                           errorBlock:errorBlock];
    }
}

#pragma mark - Social auth

- (void)logInWithFacebookSessionToken:(NSString *)sessionToken
                           completion:(void(^)(QBResponse *response, QBUUser *tUser))completion {
    
    __weak __typeof(self)weakSelf = self;
    
    [QBRequest logInWithSocialProvider:@"facebook"
                           accessToken:sessionToken
                     accessTokenSecret:nil
                          successBlock:^(QBResponse *response, QBUUser *tUser)
     {
      
         weakSelf.isAuthorized = YES;
         
         tUser.password = [QBBaseModule sharedModule].token;
         completion(response, tUser);
         
     } errorBlock:^(QBResponse *response) {
         
         [weakSelf showMessageForQBResponce:response];
         
         if (completion)
             completion(response, nil);
     }];
}

@end