//
//  QMUserProfileProtocol.h
//  QMBaseService
//
//  Created by Andrey Ivanov on 28.04.15.
//
//

#import <Foundation/Foundation.h>

@protocol QMServiceManagerProtocol <NSObject>

- (QBUUser *)currentUser;
- (BOOL)isAutorized;
- (void)handleErrorResponse:(QBResponse *)response;

@end