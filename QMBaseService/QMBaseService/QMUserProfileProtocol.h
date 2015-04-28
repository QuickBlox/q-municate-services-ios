//
//  QMUserProfileProtocol.h
//  QMBaseService
//
//  Created by Andrey Ivanov on 28.04.15.
//
//

#import <Foundation/Foundation.h>

@protocol QMUserProfileProtocol <NSObject>

- (QBUUser *)currentUser;
- (BOOL)userIsAutorized;

@end