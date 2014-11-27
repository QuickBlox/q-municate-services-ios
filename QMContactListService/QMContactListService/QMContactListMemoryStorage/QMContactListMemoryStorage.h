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
- (void)updateWithContactListItems:(NSArray *)contactListItems;

- (void)addContactRequestFromUserID:(NSUInteger)userID;
- (QBContactListItem *)contactListItemWithUserID:(NSUInteger)userID;

- (NSArray *)contactRequestUsersIDs;
- (void)confirmOrRejectContactRequestForUserID:(NSUInteger)userID;
- (NSArray *)userIDsFromContactList;

@end
