//
//  QMContactListMemoryStorage.m
//  QMContactListService
//
//  Created by Andrey on 25.11.14.
//
//

#import "QMContactListMemoryStorage.h"

@interface QMContactListMemoryStorage()

@property (strong, nonatomic) NSMutableDictionary *contactList;

@property (strong, nonatomic) NSMutableSet *contactRequestsUsersIDs;

@end

@implementation QMContactListMemoryStorage

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        self.contactList = [NSMutableDictionary dictionary];
        self.contactRequestsUsersIDs = [NSMutableSet set];
    }
    return self;
}

- (void)updateWithContactList:(QBContactList *)contactList {
    
    [self.contactList removeAllObjects];
    
    [contactList.contacts enumerateObjectsUsingBlock:^(QBContactListItem *obj,
                                                       NSUInteger idx,
                                                       BOOL *stop) {
        [self addContactListItem:obj];
    }];
    
    [contactList.pendingApproval enumerateObjectsUsingBlock:^(QBContactListItem *obj,
                                                              NSUInteger idx,
                                                              BOOL *stop) {
        [self addContactListItem:obj];
    }];
}

- (void)updateWithContactListItems:(NSArray *)contactListItems {
    
    [self.contactList removeAllObjects];
    [contactListItems enumerateObjectsUsingBlock:^(QBContactListItem *obj,
                                                   NSUInteger idx,
                                                   BOOL *stop) {
        [self addContactListItem:obj];
    }];
}

- (void)addContactListItem:(QBContactListItem *)contactListItem {
    
    self.contactList[@(contactListItem.userID)] = contactListItem;
}

- (NSArray *)userIDsFromContactList {
    
    return self.contactList.allKeys;
}

- (QBContactListItem *)contactListItemWithUserID:(NSUInteger)userID {
    
    return self.contactList[@(userID)];
}

#pragma mark - contact request

- (void)addContactRequestFromUserID:(NSUInteger)userID {
    
    [self.contactRequestsUsersIDs addObject:@(userID)];
}

- (NSArray *)contactRequestUsersIDs {
    
    return self.contactRequestsUsersIDs.allObjects;
}

- (void)confirmOrRejectContactRequestForUserID:(NSUInteger)userID {
    
    [self.contactRequestsUsersIDs removeObject:@(userID)];
}

#pragma mark - QMMemoryStorageProtocol

- (void)free {
    
    [self.contactList removeAllObjects];
    [self.contactRequestsUsersIDs removeAllObjects];
}

@end
