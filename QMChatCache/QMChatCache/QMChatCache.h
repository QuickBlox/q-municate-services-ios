//
//  QMChatCache.h
//  QMChatCache
//
//  Created by Andrey Ivanov on 06.11.14.
//
//

#import <Foundation/Foundation.h>
#import "QMDBStorage.h"

@interface QMChatCache : QMDBStorage

#pragma mark - Singleton

/**
 *  Chat cache singleton
 *
 *  @return QMChatCache instance
 */
+ (QMChatCache *)instance;

#pragma mark - Configure store

/**
 *  Setup QMChatCache stake wit store name
 *
 *  @param storeName Store name
 */
+ (void)setupDBWithStoreNamed:(NSString *)storeName;

/**
 *  Clean clean chat cache with store name
 *
 *  @param name Store name
 */
+ (void)cleanDBWithStoreName:(NSString *)name;

#pragma mark -
#pragma mark Dialogs
#pragma mark -
#pragma mark Insert / Update / Delete dialog operations

/**
 *  Insert/Update dialog to cache
 *
 *  @param dialog QBChatDialog instance
 *  @param completion Completion block is called after fetch is completed
 */
- (void)insertOrUpdateDialog:(QBChatDialog *)dialog
                  completion:(void(^)(void))completion;

/**
 *  Auto Update / Insert
 *
 *  @param dialogs    QBChatDialog collection
 *  @param completion Completion block is called after update or insert operation is completed
 */
- (void)insertOrUpdateDialogs:(NSArray *)dialogs
                   completion:(void(^)(void))completion;

/**
 *  Delete dialog from cache
 *
 *  @param dialog
 *  @param completion Completion block is called after delete operation is completed
 */
- (void)deleteDialogWithID:(NSString *)dialog
                completion:(void(^)(void))completion;

/**
 *  Delete all dialogs
 *
 *  @param completion Completion block is called after delete all dialogs operation is completed
 */
- (void)deleteAllDialogs:(void(^)(void))completion;

#pragma mark Fetch dialog operations

/**
 *   Fetch all cached dialogs
 *
 *  @param sortTerm   Attribute name to sort by.
 *  @param ascending  `YES` if the attribute should be sorted ascending, `NO` for descending.
 *  @param completion Completion block that is called after the fetch has completed. Returns an array of QBChatDialog instances
 */
- (void)dialogsSortedBy:(NSString *)sortTerm
              ascending:(BOOL)ascending
             completion:(void(^)(NSArray *dialogs))completion;

/**
 *  Fetch cached dialogs with predicate
 *
 *  Key for filtering:
 *  id
	lastMessageDate
	lastMessageText
	lastMessageUserID
	name;
	occupantsIDs
	ocupantsIDs
	photo
	recipientID
	roomJID
	type
	unreadMessagesCount
	userID
 *
 *  @param sortTerm   Attribute name to sort by.
 *  @param ascending  `YES` if the attribute should be sorted ascending, `NO` for descending.
 *  @param predicate  Predicate to evaluate objects against
 *  @param completion Completion block that is called after the fetch has completed. Returns an array of QBChatDialog instances
 */
- (void)dialogsSortedBy:(NSString *)sortTerm
              ascending:(BOOL)ascending
          withPredicate:(NSPredicate *)predicate
             completion:(void(^)(NSArray *dialogs))completion;

#pragma mark -
#pragma mark  Messages
#pragma mark -

/**
 *  Add message to cache
 *
 *  @param message    QBChatHistoryMessage instance
 *  @param dialogId   Dialog identifier
 *  @param completion Finish block
 */
- (void)insertOrUpdateMessage:(QBChatHistoryMessage *)message
                 withDialogId:(NSString *)dialogID
                   completion:(void(^)(void))completion;

/**
 *  Add message to cache
 *
 *  @param message    QBChatMessage instance
 *  @param dialogId   Dialog identifier
 *  @param completion Finish block
 */
- (void)insertOrUpdateMessage:(QBChatMessage *)message
                 withDialogId:(NSString *)dialogID
                         read:(BOOL)isRead
                   completion:(void(^)(void))completion;

/**
 *  Update or insert messages
 *
 *  @param messages   Array of messages
 *  @param dialogID   Dialog identifier
 *  @param completion Returns an array of QBChatMessages instances
 */
- (void)insertOrUpdateMessages:(NSArray *)messages
                  withDialogId:(NSString *)dialogID
                    completion:(void(^)(void))completion;

/**
 *  Fetch cached messages with dialog id and filtering with predicate
 *
 *  @param dialogId   Dialog identifier
 *  @param predicate  Filter predicate
 *  @param completion returns an array of QBChatMessages instances
 */

- (void)messagesWithDialogId:(NSString *)dialogId
                    sortedBy:(NSString *)sortTerm
                   ascending:(BOOL)ascending
                  completion:(void(^)(NSArray *array))completion;

- (void)messagesWithPredicate:(NSPredicate *)predicate
                     sortedBy:(NSString *)sortTerm
                    ascending:(BOOL)ascending
                   completion:(void(^)(NSArray *messages))completion;

/**
 *  Delete message
 *
 *  @param message    QBChatHistoryMessage message
 *  @param completion Finish block
 */
- (void)deleteMessage:(QBChatHistoryMessage *)message
           completion:(void(^)(void))completion;
/**
 *  Delete all messages
 *
 *  @param completion Completion block that is called after the delete all messages operation completed.
 */
- (void)deleteAllMessages:(void(^)(void))completion;

@end
