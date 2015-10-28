//
//  QMUsersService.h
//  QMUsersService
//
//  Created by Andrey Moskvin on 10/23/15.
//  Copyright © 2015 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMBaseService.h"
#import "QMUsersMemoryStorage.h"

@class QMCancellationToken;

@protocol QMUsersServiceDelegate;
@protocol QMUsersServiceCacheDataSource;

@interface QMUsersService : QMBaseService

/**
 *  Memory storage for users items.
 */
@property (strong, nonatomic, readonly) QMUsersMemoryStorage *usersMemoryStorage;

/**
 *  Init with service data delegate and contact list cache protocol.
 *
 *  @param serviceDataDelegate instance confirmed id<QMServiceDataDelegate> protocol
 *  @param cacheDataSource       instance confirmed id<QMUsersServiceCacheDataSource> protocol
 *
 *  @return QMContactListService instance
 */
- (instancetype)initWithServiceManager:(id<QMServiceManagerProtocol>)serviceManager
                       cacheDataSource:(id<QMUsersServiceCacheDataSource>)cacheDataSource;

/**
 *  Add instance that confirms contact list service multicaste protocol
 *
 *  @param delegate instance that confirms id<QMContactListServiceDelegate> protocol
 */
- (void)addDelegate:(id <QMUsersServiceDelegate>)delegate;

/**
 *  Remove instance that confirms contact list service multicaste protocol
 *
 *  @param delegate instance that confirms id<QMContactListServiceDelegate> protocol
 */
- (void)removeDelegate:(id <QMUsersServiceDelegate>)delegate;

/**
 *  Retrieving user if needed.
 *
 *  @param userID       id of user to retrieve
 *  @param completion   completion block with boolean value YES if retrieve was needed
 */
- (BFTask<QBUUser *> *)retrieveIfNeededUserWithID:(NSUInteger)userID;

/**
 *  Retrieving users if needed.
 *
 *  @param userIDs      array of users ids to retrieve
 *  @param completion   completion block with boolean value YES if retrieve was needed
 */
- (BFTask<NSArray<QBUUser *> *> *)retrieveIfNeededUsersWithIDs:(NSArray *)usersIDs;

/**
 *  Retrieve users with ids (with extended set of pagination parameters)
 *
 *  @param ids						ids of users which you want to retrieve
 *  @param forceDownload	force download users even if users are already downloaded and exists in cache
 *  @param completion			Block with response, page and users instances if request succeded
 */
- (BFTask<NSArray<QBUUser *> *> *)retrieveUsersWithIDs:(NSArray *)ids forceDownload:(BOOL)forceDownload;

/**
 *  Retrieve users with emails
 *
 *  @param emails     emails to search users with
 *  @param completion Block with response, page and users instances if request succeded
 */
- (BFTask<NSArray<QBUUser *> *> *)retrieveUsersWithEmails:(NSArray *)emails;

/**
 *  Retrieve users with full name
 *
 *  @param  searchText string with full name
 *  @param  pagedRequest extended set of pagination parameters
 *  @param  completion Block with response, page and users instances if request succeded
 *
 *  @return QBRequest cancelable instance
 */
- (BFTask<NSArray<QBUUser *> *> *)retrieveUsersWithFullName:(NSString *)searchText
                                               pagedRequest:(QBGeneralResponsePage *)page
                                          cancellationToken:(QMCancellationToken *)token;

/**
 *  Retrieve users with facebook ids (with extended set of pagination parameters)
 *
 *  @param facebookIDs facebook ids to search
 *  @param completion  Block with response, page and users instances if request succeded
 */
- (BFTask<NSArray<QBUUser *> *> *)retrieveUsersWithFacebookIDs:(NSArray *)facebookIDs;


@end

#pragma mark - Protocols

/**
 *  Data source for QMContactList Service
 */

@protocol QMUsersServiceCacheDataSource <NSObject>
@required

/**
 * Is called when chat service will start. Need to use for inserting initial data QMUsersMemoryStorage
 *
 *  @param block Block for provide QBUUsers collection
 */
- (void)cachedUsers:(void(^)(NSArray* collection))block;

@end

@protocol QMUsersServiceDelegate <NSObject>

@optional

- (void)usersService:(QMUsersService *)usersService didAddUsers:(NSArray<QBUUser *> *)user;

@end
