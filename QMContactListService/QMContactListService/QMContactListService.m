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

@property (strong, nonatomic) QBMulticastDelegate <QMContactsServiceDelegate> *multicastDelegate;
@property (strong, nonatomic) QMContactListMemoryStorage *contactListMemoryStorage;
@property (strong, nonatomic) QMUsersMemoryStorage *usersMemoryStorage;
@property (strong, nonatomic) NSMutableSet *retrivedIds;

@end

@implementation QMContactListService

- (void)dealloc {
    NSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
    [[QBChat instance] removeDelegate:self];
    self.contactListMemoryStorage = nil;
}

- (instancetype)initWithServiceDataDelegate:(id<QMServiceDataDelegate>)serviceDataDelegate {
    
    self = [super initWithServiceDataDelegate:serviceDataDelegate];
    if (self) {
        
        self.multicastDelegate = (id<QMContactsServiceDelegate>)[[QBMulticastDelegate alloc] init];
        self.contactListMemoryStorage = [[QMContactListMemoryStorage alloc] init];
        self.usersMemoryStorage = [[QMUsersMemoryStorage alloc] init];
        
        [[QBChat instance] addDelegate:self];
    }
    return self;
}

#pragma mark - Add Remove multicaste delegate

- (void)addDelegate:(id <QMContactsServiceDelegate>)delegate {
    
    [self.multicastDelegate addDelegate:delegate];
}

- (void)removeDelegate:(id <QMContactsServiceDelegate>)delegate {
    
    [self.multicastDelegate removeDelegate:delegate];
}

#pragma mark - QBChatDelegate

//Called in case of changing contact list
- (void)chatContactListDidChange:(QBContactList *)contactList {
    
    [self.contactListMemoryStorage updateWithContactList:contactList];
    
    __weak __typeof(self)weakSelf = self;
    
    [self retrieveUsersWithIDs:[self.contactListMemoryStorage userIDsFromContactList]
                    completion:^(QBResponse *responce, QBGeneralResponsePage *page, NSArray *users)
     {
         if (responce.success) {
             
             if ([weakSelf.multicastDelegate respondsToSelector:@selector(contactsServiceContactListDidUpdate)]) {
                 
                 [weakSelf.multicastDelegate contactsServiceContactListDidUpdate];
             }
         }
     }];
}

//Called in case receiving contact request
//@param userID User ID from which received contact request

- (void)chatDidReceiveContactAddRequestFromUser:(NSUInteger)userID {
    
    [self.contactListMemoryStorage addContactRequestWithUserID:userID];
    
    QBUUser *user = [self.usersMemoryStorage userWithID:userID];
    
    if (user) {
        
        if ([self.multicastDelegate respondsToSelector:@selector(contactsServiceContactRequestUsersListChanged)]) {
            
            [self.multicastDelegate contactsServiceContactRequestUsersListChanged];
        }
    }
    else {
        
        __weak __typeof(self)weakSelf = self;
        
        [self retrieveUsersWithIDs:@[@(userID)]
                        completion:^(QBResponse *responce, QBGeneralResponsePage *page, NSArray *users)
         {
             if ([weakSelf.multicastDelegate respondsToSelector:@selector(contactsServiceContactRequestUsersListChanged)]) {
                 
                 [weakSelf.multicastDelegate contactsServiceContactRequestUsersListChanged];
             }
         }];
    }
}

- (NSMutableSet *)checkExistIds:(NSArray *)ids {
    
    NSMutableSet *toFetch = [NSMutableSet setWithArray:ids];
    
    for (NSNumber *userID in ids) {
        
        QBUUser *savedUser = [self.usersMemoryStorage userWithID:userID.unsignedIntegerValue];
        BOOL inProgress = [self.retrivedIds containsObject:userID];
        
        if (savedUser || inProgress) {
            [toFetch removeObject:userID];
        }
    }
    
    return toFetch;
}

- (void)retrieveUsersWithIDs:(NSArray *)ids
                  completion:(void(^)(QBResponse *responce, QBGeneralResponsePage *page, NSArray * users))completion {
    
    NSSet *toRetrive = [self checkExistIds:ids].copy;
    
    NSLog(@"RetrieveUsers %@", toRetrive);
    
    if (toRetrive.count == 0) {
        completion(nil, nil, nil);
    }
    else {
        
        QBGeneralResponsePage *pageResponce =
        [QBGeneralResponsePage responsePageWithCurrentPage:1
                                                   perPage:toRetrive.count < 100 ? toRetrive.count : 100];
        __weak __typeof(self)weakSelf = self;
        
        [self.retrivedIds unionSet:toRetrive];
        
        [QBRequest usersWithIDs:toRetrive.allObjects
                           page:pageResponce
                   successBlock:^(QBResponse *responce, QBGeneralResponsePage *page, NSArray * users)
         {
             for (QBUUser *user in users) {
                 [weakSelf.retrivedIds removeObject:@(user.ID)];
             }
             
             [weakSelf.usersMemoryStorage addUsers:users];
             
             if (completion) {
                 completion(responce, page, users);
             }
             
         } errorBlock:^(QBResponse *responce) {
             
             completion(responce, nil, nil);
         }];
    }
}

#pragma mark - ContactList Request

- (void)addUserToContactListRequest:(QBUUser *)user
                         completion:(void(^)(BOOL success))completion {
    
    BOOL success = [[QBChat instance] addUserToContactListRequest:user.ID];
    if (success) {
        [self.usersMemoryStorage addUser:user];
    }
    
    if (completion) completion(success);
}

- (void)removeUserFromContactListWithUserID:(NSUInteger)userID
                                 completion:(void(^)(BOOL success))completion {
    
    BOOL success = [[QBChat instance] removeUserFromContactList:userID sentBlock:^(NSError *error) {
        
        completion(success);
    }];
}

- (void)confirmAddContactRequest:(NSUInteger)userID
                      completion:(void(^)(BOOL success))completion {
    
    __weak __typeof(self)weakSelf = self;
    BOOL success = [[QBChat instance] confirmAddContactRequest:userID sentBlock:^(NSError *error) {
        
        [weakSelf.contactListMemoryStorage confirmOrRejectContactRequestForUserID:userID];
    }];
    
    completion(success);
}

//- (NSArray *)friends {
//    
//    NSArray *ids = [self idsFromContactListItems];
//    NSArray *allFriends = [self usersWithIDs:ids];
//    
//    return allFriends;
//}

- (void)rejectAddContactRequest:(NSUInteger)userID
                     completion:(void(^)(BOOL success))completion {
    
    BOOL success = [[QBChat instance]  rejectAddContactRequest:userID sentBlock:^(NSError *error) {
        [self.contactListMemoryStorage confirmOrRejectContactRequestForUserID:userID];
    }];
    
    completion(success);
}

@end
