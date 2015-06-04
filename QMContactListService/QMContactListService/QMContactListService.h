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
#import "QMUsersMemoryStorage.h"
#import "QBUUser+CustomData.h"

@class QBGeneralResponsePage;

typedef void(^QMCacheCollection)(NSArray *collection);

@protocol QMContactListServiceDelegate;
@protocol QMContactListServiceCacheDelegate;

@interface QMContactListService : QMBaseService

@property (strong, nonatomic, readonly) QMContactListMemoryStorage *contactListMemoryStorage;
@property (strong, nonatomic, readonly) QMUsersMemoryStorage *usersMemoryStorage;


/**
 *  Init with service data delegate and contact list cache protocol.
 *
 *  @param serviceDataDelegate instance confirmed id<QMServiceDataDelegate> protocol
 *  @param cacheDelegate       instance confirmed id<QMContactListServiceCacheDelegate> protocol
 *
 *  @return QMContactListService instance
 */
- (instancetype)initWithServiceManager:(id<QMServiceManagerProtocol>)serviceManager
                         cacheDelegate:(id<QMContactListServiceCacheDelegate>)cacheDelegate;

/**
 *  Add instance that confirms contact list service multicaste protocol
 *
 *  @param delegate instance that confirms id<QMContactListServiceDelegate> protocol
 */
- (void)addDelegate:(id <QMContactListServiceDelegate>)delegate;

/**
 *  Remove instance that confirms contact list service multicaste protocol
 *
 *  @param delegate instance that confirms id<QMContactListServiceDelegate> protocol
 */
- (void)removeDelegate:(id <QMContactListServiceDelegate>)delegate;

/**
 *  Retrieve users with ids (with extended set of pagination parameters)
 *
 *  @param ids						ids of users which you want to retrieve
 *  @param forceDownload	force download users even if users are already downloaded and exists in cache
 *  @param completion			Block with response, page and users instances if request succeded
 */
- (void)retrieveUsersWithIDs:(NSArray *)ids forceDownload:(BOOL)forceDownload completion:(void(^)(QBResponse *response, QBGeneralResponsePage *page, NSArray * users))completion;

/**
 *  Retrive users with ids (with extended set of pagination parameters)
 *
 *  @param cahatDialog QBChatDialog instance
 *  @param completion Block with response, page and users instances if request succeded
 */
- (void)retriveUsersForChatDialog:(QBChatDialog *)cahtDialog
                       completion:(void(^)(QBResponse *responce, QBGeneralResponsePage *page, NSArray * users))completion;

/**
 *  Add user to contact list request
 *
 *  @param user       user which you would like to add to contact list
 *  @param completion completion block
 */
- (void)addUserToContactListRequest:(QBUUser *)user
                         completion:(void(^)(BOOL success))completion;
/**
 *  <#Description#>
 *
 *  @param userID     <#userID description#>
 *  @param completion <#completion description#>
 */
- (void)removeUserFromContactListWithUserID:(NSUInteger)userID
                                 completion:(void(^)(BOOL success))completion;
/**
 *  <#Description#>
 *
 *  @param userID     <#userID description#>
 *  @param completion <#completion description#>
 */
- (void)acceptContactRequest:(NSUInteger)userID
                      completion:(void (^)(BOOL success))completion;
/**
 *  <#Description#>
 *
 *  @param userID     <#userID description#>
 *  @param completion <#completion description#>
 */
- (void)rejectContactRequest:(NSUInteger)userID
                     completion:(void(^)(BOOL success))completion;

@end

#pragma mark - Protocols

@protocol QMContactListServiceCacheDelegate <NSObject>
@required

- (void)cachedUsers:(QMCacheCollection)block;
- (void)cachedContactListItems:(QMCacheCollection)block;

@end

@protocol QMContactListServiceDelegate <NSObject>
@optional

- (void)contactListServiceDidLoadCache;
- (void)contactListService:(QMContactListService *)contactListService contactListDidChange:(QBContactList *)contactList;
- (void)contactListService:(QMContactListService *)contactListService addRequestFromUser:(QBUUser *)user;
- (void)contactListService:(QMContactListService *)contactListService didAddUser:(QBUUser *)user;
- (void)contactListService:(QMContactListService *)contactListService didAddUsers:(NSArray *)users;
- (void)contactListService:(QMContactListService *)contactListService didUpdateUser:(QBUUser *)user;
- (void)contactListService:(QMContactListService *)contactListService didFinishRetriveUsersForChatDialog:(QBChatDialog *)dialog;

@end