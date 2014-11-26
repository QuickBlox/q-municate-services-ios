//
//  QMContactListMemoryStorage.h
//  QMContactListService
//
//  Created by Andrey on 25.11.14.
//
//

#import <Foundation/Foundation.h>

@interface QMContactListMemoryStorage : NSObject

- (NSArray *)friends;
- (void)addUsers:(NSArray *)users;
- (NSArray *)idsWithUsers:(NSArray *)users;
- (NSArray *)usersWithIDs:(NSArray *)ids;
- (void)addUser:(QBUUser *)user;
- (QBUUser *)userWithID:(NSUInteger)userID;
- (NSArray *)checkExistIds:(NSArray *)ids;
- (NSArray *)idsFromContactListItems;
- (NSArray *)contactRequestUsers;
- (QBContactListItem *)contactItemWithUserID:(NSUInteger)userID;
- (NSArray *)usersHistory;

@end
