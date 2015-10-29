//
//  QMUsersService.m
//  QMUsersService
//
//  Created by Andrey Moskvin on 10/23/15.
//  Copyright © 2015 Quickblox. All rights reserved.
//

#import "QMUsersService.h"
#import "QMCancellationToken.h"

@interface QMUsersService () <QBChatDelegate>

@property (strong, nonatomic) QBMulticastDelegate <QMUsersServiceDelegate> *multicastDelegate;
@property (strong, nonatomic) QMUsersMemoryStorage *usersMemoryStorage;
@property (weak, nonatomic) id<QMUsersServiceCacheDataSource> cacheDataSource;

@end

@implementation QMUsersService {
    BFTask* loadFromCacheTask;
}

- (void)dealloc {
    
    NSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
    [[QBChat instance] removeDelegate:self];
    self.usersMemoryStorage = nil;
}

- (instancetype)initWithServiceManager:(id<QMServiceManagerProtocol>)serviceManager cacheDataSource:(id<QMUsersServiceCacheDataSource>)cacheDataSource
{
    self = [super initWithServiceManager:serviceManager];
    if (self) {
        self.cacheDataSource = cacheDataSource;
    }
    return self;
}

- (void)serviceWillStart
{
    self.multicastDelegate = (id<QMUsersServiceDelegate>)[[QBMulticastDelegate alloc] init];
    self.usersMemoryStorage = [[QMUsersMemoryStorage alloc] init];
}

#pragma mark - Tasks

- (BFTask *)loadFromCache
{
    if (loadFromCacheTask == nil) {
        BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
        
        if ([self.cacheDataSource respondsToSelector:@selector(cachedUsers:)]) {
            @weakify(self);
            [self.cacheDataSource cachedUsers:^(NSArray *collection) {
                @strongify(self);
                [self.usersMemoryStorage addUsers:collection];
                [source setResult:collection];
            }];
            loadFromCacheTask = source.task;
            return loadFromCacheTask;
        } else {
            loadFromCacheTask = [BFTask taskWithResult:nil];
        }
    }
    
    return loadFromCacheTask;
}

#pragma mark - Add Remove multicaste delegate

- (void)addDelegate:(id <QMUsersServiceDelegate>)delegate {
    
    [self.multicastDelegate addDelegate:delegate];
}

- (void)removeDelegate:(id <QMUsersServiceDelegate>)delegate {
    
    [self.multicastDelegate removeDelegate:delegate];
}

#pragma mark - Retrive users

- (BFTask<QBUUser *> *)retrieveIfNeededUserWithID:(NSUInteger)userID
{
    return (BFTask<QBUUser *> *)[[self retrieveIfNeededUsersWithIDs:@[@(userID)]] continueWithBlock:^id(BFTask *task) {
        return [BFTask taskWithResult:[task.result firstObject]];
    }];
}

- (BFTask<NSArray<QBUUser *> *> *)retrieveIfNeededUsersWithIDs:(NSArray *)usersIDs
{
    NSParameterAssert(usersIDs);
    @weakify(self);
    return [[self loadFromCache] continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        NSArray* users = [self.usersMemoryStorage usersWithIDs:usersIDs];
        
        if (users.count == usersIDs.count) {
            return [BFTask taskWithResult:users];
        }
        
        return [self retrieveUsersWithIDs:[self.usersMemoryStorage usersIDsByExcludingUsersIDs:usersIDs]
                               foundUsers:users
                            forceDownload:YES];
    }];
}

- (BFTask<NSArray<QBUUser *> *> *)retrieveUsersWithIDs:(NSArray *)ids foundUsers:(NSArray *)foundUsers forceDownload:(BOOL)forceDownload;
{
    if (ids.count == 0) {
        return [BFTask taskWithResult:foundUsers];
    }

    @weakify(self);
    return [[self loadFromCache] continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        NSSet *usersIDs = [NSSet setWithArray:ids];
        
        QBGeneralResponsePage *pageResponse =
        [QBGeneralResponsePage responsePageWithCurrentPage:1 perPage:usersIDs.count < 100 ? usersIDs.count : 100];
        
        BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
        
        [QBRequest usersWithIDs:usersIDs.allObjects page:pageResponse successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray * users) {
            [self.usersMemoryStorage addUsers:users];
            
            if ([self.multicastDelegate respondsToSelector:@selector(usersService:didAddUsers:)]) {
                [self.multicastDelegate usersService:self didAddUsers:users];
            }
            
            [source setResult:[foundUsers arrayByAddingObjectsFromArray:users]];
        } errorBlock:^(QBResponse *response) {
            [source setError:response.error.error];
        }];
        
        return source.task;
    }];
}


- (BFTask<NSArray<QBUUser *> *> *)retrieveUsersWithEmails:(NSArray *)emails
{
    NSParameterAssert(emails);
    
    @weakify(self)
    return [[self loadFromCache] continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        
        NSArray* foundUsers = [self.usersMemoryStorage usersWithEmails:emails];
        
        if (foundUsers.count == emails.count) {
            return [BFTask taskWithResult:foundUsers];
        }
    
        BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
    
        NSArray* emailsToRetrieve = [self.usersMemoryStorage usersEmailsByExcludingEmails:emails];
        
        [QBRequest usersWithEmails:emailsToRetrieve successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray *users) {
            
            [self.usersMemoryStorage addUsers:users];
            
            if ([self.multicastDelegate respondsToSelector:@selector(usersService:didAddUsers:)]) {
                [self.multicastDelegate usersService:self didAddUsers:users];
            }
            
            [source setResult:[foundUsers arrayByAddingObjectsFromArray:users]];
        } errorBlock:^(QBResponse *response) {
            [source setError:response.error.error];
        }];
        
        return source.task;
    }];
}

- (BFTask<NSArray<QBUUser *> *> *)searchUsersWithFullName:(NSString *)searchText
{
    @weakify(self);
    return [[self loadFromCache] continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        
        BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
        
        [QBRequest usersWithFullName:searchText page:[QBGeneralResponsePage responsePageWithCurrentPage:1 perPage:100]
                        successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray *users) {
            [self.usersMemoryStorage addUsers:users];
            
            if ([self.multicastDelegate respondsToSelector:@selector(usersService:didAddUsers:)]) {
                [self.multicastDelegate usersService:self didAddUsers:users];
            }
            
            [source setResult:users];
        } errorBlock:^(QBResponse *response) {
            [source setError:response.error.error];
        }];
        
        return source.task;
    }];
}


- (BFTask<NSArray<QBUUser *> *> *)retrieveUsersWithFacebookIDs:(NSArray *)facebookIDs
{
    NSParameterAssert(facebookIDs);
    
    @weakify(self);
    return [[self loadFromCache] continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        
        NSArray* foundUsers = [self.usersMemoryStorage usersWithFacebookIDs:facebookIDs];
        
        if (foundUsers.count == 0) {
            return [BFTask taskWithResult:foundUsers];
        }
        
        BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
        
        QBGeneralResponsePage *pageResponse =
        [QBGeneralResponsePage responsePageWithCurrentPage:1 perPage:facebookIDs.count < 100 ? facebookIDs.count : 100];
    
        NSArray* facebookIDsToRetrieve = [self.usersMemoryStorage usersFacebookIDsByExcludingFacebookIDs:facebookIDs];

        [QBRequest usersWithFacebookIDs:facebookIDsToRetrieve
                                   page:pageResponse
                           successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray *users) {
            [self.usersMemoryStorage addUsers:users];
            
            if ([self.multicastDelegate respondsToSelector:@selector(usersService:didAddUsers:)]) {
                [self.multicastDelegate usersService:self didAddUsers:users];
            }
            
            [source setResult:[foundUsers arrayByAddingObjectsFromArray:users]];
        } errorBlock:^(QBResponse *response) {
            [source setError:response.error.error];
        }];
        return source.task;
    }];
}

@end
