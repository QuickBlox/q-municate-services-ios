//
//  QMUsersMemoryStorage.h
//  QMContactListService
//
//  Created by Andrey on 26.11.14.
//
//

#import <Foundation/Foundation.h>
#import "QMMemoryStorageProtocol.h"

@protocol QMUsersMemoryStorageDelegate <NSObject>

- (NSArray *)contactsIDS;

@end

@interface QMUsersMemoryStorage : NSObject <QMMemoryStorageProtocol>

@property (weak, nonatomic) id <QMUsersMemoryStorageDelegate> delegate;

- (void)addUser:(QBUUser *)user;
- (void)addUsers:(NSArray *)users;

- (QBUUser *)userWithID:(NSUInteger)userID;
- (NSArray *)usersWithIDs:(NSArray *)ids;

#pragma mark - Sorting

- (NSArray *)unsorterdUsers;
- (NSArray *)usersSortedByKey:(NSString *)key ascending:(BOOL)ascending;

#pragma mark Contacts

- (NSArray *)contactsSortedByKey:(NSString *)key ascending:(BOOL)ascending;

#pragma mark Utils

- (NSArray *)usersWithIDs:(NSArray *)IDs withoutID:(NSUInteger)ID;
- (NSString *)joinedNamesbyUsers:(NSArray *)users;

@end
