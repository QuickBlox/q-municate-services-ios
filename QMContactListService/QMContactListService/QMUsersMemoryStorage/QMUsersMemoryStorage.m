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
    
    NSString *key = [NSString stringWithFormat:@"%lu", (unsigned long)user.ID];
    self.users[key] = user;
}

- (void)addUsers:(NSArray *)users {
    
    [users enumerateObjectsUsingBlock:^(QBUUser *obj, NSUInteger idx, BOOL *stop) {
        [self addUser:obj];
    }];
}
- (QBUUser *)userWithID:(NSUInteger)userID {
    
    NSString *stingID = [NSString stringWithFormat:@"%lu", (unsigned long)userID];
    QBUUser *user = self.users[stingID];
    return user;
}

- (NSArray *)unsorterdUsersFromMemoryStorage {
    
    NSArray *allUsers = self.users.allValues;
    return allUsers;
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

@end
