//
//  QMUsersMemoryStorage.h
//  QMContactListService
//
//  Created by Andrey on 26.11.14.
//
//

#import <Foundation/Foundation.h>

@interface QMUsersMemoryStorage : NSObject

- (void)addUser:(QBUUser *)user;
- (void)addUsers:(NSArray *)users;

- (NSArray *)unsorterdUsersFromMemoryStorage;
- (QBUUser *)userWithID:(NSUInteger)userID;

@end
