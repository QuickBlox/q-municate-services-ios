//
//  QMUsersMemoryStorage.m
//  QMContactListService
//
//  Created by Andrey on 26.11.14.
//
//

#import "QMUsersMemoryStorage.h"

@interface QMUsersMemoryStorage()

@property (strong, nonatomic) NSMutableDictionary *users;

@end

@implementation QMUsersMemoryStorage

- (instancetype)init {
    
    self = [super init];
    if (self) {
        self.users = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)addUser:(QBUUser *)user {
    
    NSString *key = [NSString stringWithFormat:@"%tu", user.ID];
    self.users[key] = user;
}

- (void)addUsers:(NSArray *)users {
    
    [users enumerateObjectsUsingBlock:^(QBUUser *user,
                                        NSUInteger idx,
                                        BOOL *stop) {
        [self addUser:user];
    }];
}

- (QBUUser *)userWithID:(NSUInteger)userID {
    
    NSString *stingID = [NSString stringWithFormat:@"%tu", userID];
    QBUUser *user = self.users[stingID];
    
    return user;
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

- (NSArray *)idsWithUsers:(NSArray *)users {

    NSMutableSet *ids = [NSMutableSet set];
    for (QBUUser *user in users) {
        
        [ids addObject:@(user.ID)];
    }
    
    return [ids allObjects];
}

#pragma mark - Sorting

- (NSArray *)unsorterd {
    
    NSArray *allUsers = self.users.allValues;
    return allUsers;
}

- (NSArray *)sortedByName:(BOOL)ascending {
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"fullName" ascending:ascending];
    return [self.unsorterd sortedArrayUsingDescriptors:@[sort]];
}

#pragma mark - QMMemoryStorageProtocol

- (void)free {
    
    [self.users removeAllObjects];
}

@end
