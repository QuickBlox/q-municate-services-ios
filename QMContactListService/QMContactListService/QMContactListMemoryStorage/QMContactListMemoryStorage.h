//
//  QMContactListMemoryStorage.h
//  QMContactListService
//
//  Created by Andrey on 25.11.14.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMMemoryStorageProtocol.h"

/**
 *  Contact list memory storage
 */
@interface QMContactListMemoryStorage : NSObject <QMMemoryStorageProtocol>

/**
 *  Update memory storage with QBContactList instance
 *
 *  @param contactList QBContactList instance
 *
 */
- (void)updateWithContactList:(QBContactList *)contactList;
- (void)updateWithContactListItems:(NSArray *)contactListItems;

- (QBContactListItem *)contactListItemWithUserID:(NSUInteger)userID;
- (NSArray *)userIDsFromContactList;

@end
