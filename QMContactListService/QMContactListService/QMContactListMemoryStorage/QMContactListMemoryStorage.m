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
    
    [contactList.contacts enumerateObjectsUsingBlock:^(QBContactListItem *contactListItem, NSUInteger idx, BOOL *stop) {
        self.contactList[@(contactListItem.userID)] = contactListItem;
    }];
    
    [contactList.pendingApproval enumerateObjectsUsingBlock:^(QBContactListItem *contactListItem, NSUInteger idx, BOOL *stop) {
        self.contactList[@(contactListItem.userID)] = contactListItem;
    }];
}

- (void)updateWithContactListItems:(NSArray *)contactListItems {
    
    [self.contactList removeAllObjects];
    [contactListItems enumerateObjectsUsingBlock:^(QBContactListItem *contactListItem, NSUInteger idx, BOOL *stop) {
        self.contactList[@(contactListItem.userID)] = contactListItem;
    }];
}

- (NSArray *)userIDsFromContactList {
    
    return self.contactList.allKeys;
}

- (QBContactListItem *)contactListItemWithUserID:(NSUInteger)userID {
    
    return self.contactList[@(userID)];
}

#pragma mark - Contact request

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
