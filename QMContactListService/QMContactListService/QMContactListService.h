//
//  QMContactsService.h
//  Q-municate
//
//  Created by Ivanov A.V on 14/02/2014.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMBaseService.h"
#import "QMContactListMemoryStorage.h"

@class QBGeneralResponsePage;
@protocol QMContactsServiceDelegate;

@interface QMContactListService : QMBaseService

@property (strong, nonatomic, readonly) QMContactListMemoryStorage *contactListMemoryStorage;

- (void)addDelegate:(id <QMContactsServiceDelegate>)delegate;
- (void)removeDelegate:(id <QMContactsServiceDelegate>)delegate;

- (void)retrieveUsersWithIDs:(NSArray *)idsToFetch
                  completion:(void(^)(QBResponse *responce, QBGeneralResponsePage *page, NSArray * users))completion;

- (void)addUserToContactListRequest:(QBUUser *)user
                         completion:(void(^)(BOOL success))completion;

- (void)removeUserFromContactListWithUserID:(NSUInteger)userID
                                 completion:(void(^)(BOOL success))completion;

- (void)confirmAddContactRequest:(NSUInteger)userID
                      completion:(void (^)(BOOL success))completion;

- (void)rejectAddContactRequest:(NSUInteger)userID
                     completion:(void(^)(BOOL success))completion;

@end

@protocol QMContactsServiceDelegate <NSObject>
@optional
- (void)contactsServiceContactListDidUpdate;
- (void)contactsServiceContactRequestUsersListChanged;
- (void)contactsServiceUsersHistoryUpdated;
@end
