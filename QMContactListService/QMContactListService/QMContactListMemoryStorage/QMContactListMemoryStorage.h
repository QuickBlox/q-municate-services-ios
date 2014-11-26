//
//  QMContactListMemoryStorage.h
//  QMContactListService
//
//  Created by Andrey on 25.11.14.
//
//

#import <Foundation/Foundation.h>
/**
 *  Contact list memory storage
 */
@interface QMContactListMemoryStorage : NSObject

/**
 *  Update memory storage with QBContactList instance
 *
 *  @param contactList QBContactList instance
 *
 */

- (void)updateWithContactList:(QBContactList *)contactList;


- (NSArray *)contactRequestUsersIDs;
- (void)addContactRequestWithUserID:(NSUInteger)userID;
- (void)confirmOrRejectContactRequestForUserID:(NSUInteger)userID;

- (NSArray *)userIDsFromContactList;



- (NSArray *)friends;

- (void)addUsers:(NSArray *)users;

- (NSArray *)idsWithUsers:(NSArray *)users;


- (void)addUser:(QBUUser *)user;

- (QBUUser *)userWithID:(NSUInteger)userID;

- (NSArray *)checkExistIds:(NSArray *)ids;

- (NSArray *)idsFromContactListItems;

- (NSArray *)contactRequestUsers;

- (QBContactListItem *)contactItemWithUserID:(NSUInteger)userID;

- (NSArray *)usersHistory;

@end
