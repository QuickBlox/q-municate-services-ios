//
//  QMUserProfileProtocol.h
//  QMBaseService
//
//  Created by Andrey Ivanov on 28.04.15.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol QMServiceManagerProtocol <NSObject>
@required

- (QBUUser *)currentUser;
- (BOOL)isAutorized;
- (void)handleErrorResponse:(QBResponse *)response;

@end