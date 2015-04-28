//
//  QMUsersMemoryStorage.h
//  QMContactListService
//
//  Created by Andrey on 26.11.14.
//
//

#import <Foundation/Foundation.h>
#import "QMMemoryStorageProtocol.h"

@interface QMUsersMemoryStorage : NSObject <QMMemoryStorageProtocol>

- (void)addUser:(QBUUser *)user;
- (void)addUsers:(NSArray *)users;

- (QBUUser *)userWithID:(NSUInteger)userID;
- (NSArray *)usersWithIDs:(NSArray *)ids;

#pragma mark - Sorting

- (NSArray *)unsorterd;
- (NSArray *)sortedByName:(BOOL)ascending;

@end
