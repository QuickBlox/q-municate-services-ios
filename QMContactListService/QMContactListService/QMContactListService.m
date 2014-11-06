//
//  QMContactsService.m
//  Q-municate
//
//  Created by Andrey Ivanov on 14/02/2014.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMContactListService.h"

@interface QMContactListService()

<QBChatDelegate>

@property (strong, nonatomic) NSMutableArray *contactList;
@property (strong, nonatomic) NSMutableSet *confirmRequestUsersIDs;
@property (strong, nonatomic) QBMulticastDelegate <QMContactsServiceDelegate> *multicastDelegate;
@property (strong, nonatomic) NSMutableDictionary *users;
@property (strong, nonatomic) NSMutableSet *retrivedIds;

@end

@implementation QMContactListService

- (instancetype)init {
    
    self = [super init];
    if (self) {
        self.users = [NSMutableDictionary dictionary];
        self.contactList = [NSMutableArray array];
        self.retrivedIds = [NSMutableSet set];
        self.confirmRequestUsersIDs = [NSMutableSet new];
        
        self.multicastDelegate = (id<QMContactsServiceDelegate>)[[QBMulticastDelegate alloc] init];
    }
    return self;
}

- (void)addDelegate:(id <QMContactsServiceDelegate>)delegate {
    
    [self.multicastDelegate addDelegate:delegate];
}

- (void)removeDelegate:(id <QMContactsServiceDelegate>)delegate {
    
    [self.multicastDelegate removeDelegate:delegate];
}

- (void)configure {
    [super configure];
    [[QBChat instance] addDelegate:self];
}

- (void)destroy {
    [super destroy];
    
    [[QBChat instance] removeDelegate:self];
    [self.users removeAllObjects];
    [self.contactList removeAllObjects];
}

#pragma mark - QBChatDelegate

- (void)chatContactListDidChange:(QBContactList *)contactList {
    
    [self.contactList removeAllObjects];
    [self.contactList addObjectsFromArray:contactList.pendingApproval];
    [self.contactList addObjectsFromArray:contactList.contacts];
    
    __weak __typeof(self)weakSelf = self;
    [self retrieveUsersWithIDs:[self idsFromContactListItems]
                    completion:^(QBResponse *responce, QBGeneralResponsePage *page, NSArray *users)
    {
        if (responce.success) {
            [weakSelf.multicastDelegate contactsServiceContactListDidUpdate];
        }
    }];
}

- (void)chatDidReceiveContactAddRequestFromUser:(NSUInteger)userID {
    
    [self.confirmRequestUsersIDs addObject:@(userID)];
    
    QBUUser *user = [self userWithID:userID];
    
    if (user) {
        [self.multicastDelegate contactsServiceContactRequestUsersListChanged];
    }
    else {
        __weak __typeof(self)weakSelf = self;
        [self retrieveUsersWithIDs:@[@(userID)]
                        completion:^(QBResponse *responce, QBGeneralResponsePage *page, NSArray *users)
        {
            if (responce.success) {
                [weakSelf.multicastDelegate contactsServiceContactRequestUsersListChanged];
            }
        }];
    }
}

- (NSArray *)idsFromContactListItems {
    
    NSMutableArray *idsToFetch = [NSMutableArray new];
    NSArray *contactListItems = self.contactList;
    
    for (QBContactListItem *item in contactListItems) {
        [idsToFetch addObject:@(item.userID)];
    }
    
    return idsToFetch;
}

- (NSArray *)usersHistory {
    return [self.users allValues];
}

- (QBUUser *)userWithID:(NSUInteger)userID {
    
    NSString *stingID = [NSString stringWithFormat:@"%d", userID];
    QBUUser *user = self.users[stingID];
    return user;
}

- (void)addUsers:(NSArray *)users {
    
    for (QBUUser *user in users) {
        [self addUser:user];
    }
    
    [self.multicastDelegate contactsServiceUsersHistoryUpdated];
}

- (void)addUser:(QBUUser *)user {
    
    NSString *key = [NSString stringWithFormat:@"%d", user.ID];
    self.users[key] = user;
}

- (NSArray *)checkExistIds:(NSArray *)ids {
    
    NSMutableSet *idsToFetch = [NSMutableSet setWithArray:ids];
    
    for (NSNumber *userID in ids) {
        
        QBUUser *user = [self userWithID:userID.integerValue];
        BOOL inProgress = [self.retrivedIds containsObject:userID];
        
        if (user || inProgress) {
            [idsToFetch removeObject:userID];
        }
    }
    
    return [idsToFetch allObjects];
}

- (void)retrieveUsersWithIDs:(NSArray *)idsToFetch
                  completion:(void(^)(QBResponse *responce, QBGeneralResponsePage *page, NSArray * users))completion {
    
    NSArray *filteredIDs = [self checkExistIds:idsToFetch];
    NSLog(@"RetrieveUsers %@", filteredIDs);
    
    if (filteredIDs.count == 0) {
        completion(nil, nil, nil);
    }
    else {
        
        QBGeneralResponsePage *pageResponce =
        [QBGeneralResponsePage responsePageWithCurrentPage:1
                                                   perPage:filteredIDs.count < 100 ? filteredIDs.count : 100];
        
        __weak __typeof(self)weakSelf = self;
        
        [self.retrivedIds addObjectsFromArray:filteredIDs];
        
        [QBRequest usersWithIDs:filteredIDs
                           page:pageResponce
                   successBlock:
         //Cache retrived users in memory
         ^(QBResponse *responce, QBGeneralResponsePage *page, NSArray * users) {
             //
             for (QBUUser *user in users) {
                 [weakSelf.retrivedIds removeObject:@(user.ID)];
             }
             
             [weakSelf addUsers:users];
             
             if (completion) {
                 completion(responce, page, users);
             }
             
         } errorBlock:^(QBResponse *responce) {
             completion(responce, nil, nil);
         }];
    }
}

/**
 @param QBUUser ID
 @return QBContactListItem from chaced contactList
 */

- (QBContactListItem *)contactItemWithUserID:(NSUInteger)userID {
    
    for (QBContactListItem *item in self.contactList) {
        
        if (item.userID == userID) {
            return item;
        }
    }
    
    return nil;
}

- (NSArray *)idsWithUsers:(NSArray *)users {
    
    NSMutableSet *ids = [NSMutableSet set];
    for (QBUUser *user in users) {
        [ids addObject:@(user.ID)];
    }
    return [ids allObjects];
}


- (NSArray *)usersWithIDs:(NSArray *)ids {
    
    NSMutableArray *allFriends = [NSMutableArray array];
   
    for (NSNumber * friendID in ids) {
        QBUUser *user = [self userWithID:friendID.integerValue];
       
        if (user) {
            [allFriends addObject:user];
        }
    }
    
    return allFriends;
}

- (NSArray *)friends {
    
    NSArray *ids = [self idsFromContactListItems];
    NSArray *allFriends = [self usersWithIDs:ids];
    
    return allFriends;
}

- (NSArray *)contactRequestUsers
{
    NSArray *ids = [self.confirmRequestUsersIDs allObjects];
    NSArray *users = [self usersWithIDs:ids];
    
    return users;
}

#pragma mark - ContactList Request

- (void)addUserToContactListRequest:(QBUUser *)user
                         completion:(void(^)(BOOL success))completion {
    
    BOOL success = [[QBChat instance] addUserToContactListRequest:user.ID];
    if (success) {
        [self addUser:user];
    }
    
    if (completion) completion(success);
}

- (void)removeUserFromContactListWithUserID:(NSUInteger)userID
                                 completion:(void(^)(BOOL success))completion {
    
    BOOL success = [[QBChat instance] removeUserFromContactList:userID];
    
    completion(success);
}

- (void)confirmAddContactRequest:(NSUInteger)userID
                      completion:(void(^)(BOOL success))completion {
    
    BOOL success = [[QBChat instance]  confirmAddContactRequest:userID];
    [self.confirmRequestUsersIDs removeObject:@(userID)];
    
    completion(success);
}

- (void)rejectAddContactRequest:(NSUInteger)userID
                     completion:(void(^)(BOOL success))completion {
    
    BOOL success = [[QBChat instance]  rejectAddContactRequest:userID];
    [self.confirmRequestUsersIDs removeObject:@(userID)];
    
    completion(success);
}

@end
