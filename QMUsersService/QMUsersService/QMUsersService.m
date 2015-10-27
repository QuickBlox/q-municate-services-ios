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

- (BFTask *)loadFromCache
{
    if (loadFromCacheTask == nil) {
        BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
        
        if ([self.cacheDataSource respondsToSelector:@selector(cachedUsers:)]) {
            __weak __typeof(self)weakSelf = self;
            [self.cacheDataSource cachedUsers:^(NSArray *collection) {
                __typeof(self) strongSelf = weakSelf;
                [strongSelf.usersMemoryStorage addUsers:collection];
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

- (BFTask *)retrieveIfNeededUserWithID:(NSUInteger)userID
{
    return [self retrieveIfNeededUsersWithIDs:@[@(userID)]];
}

- (BFTask *)retrieveIfNeededUsersWithIDs:(NSArray *)usersIDs
{
    __weak __typeof(self)weakSelf = self;
    return [[self loadFromCache] continueWithBlock:^id(BFTask *task) {
        __typeof(self) strongSelf = weakSelf;
        NSArray *memoryStorageUsers = [self.usersMemoryStorage usersWithIDs:usersIDs];
        
        if (memoryStorageUsers.count != usersIDs.count) {
            NSMutableArray *mutableUsersIDs = usersIDs.mutableCopy;
            
            for (QBUUser *user in memoryStorageUsers) {
                [mutableUsersIDs removeObject:@(user.ID)];
              }
            
            return [strongSelf retrieveUsersWithIDs:mutableUsersIDs forceDownload:YES];
        } else {
            return [BFTask taskWithError:[NSError errorWithDomain:@"com.q-municate-services"
                                                             code:-1100
                                                         userInfo:@{NSLocalizedRecoverySuggestionErrorKey : @"Retrieve from server was not needed!"}]];
        }
    }];
}

- (BFTask<NSArray<QBUUser *> *> *)retrieveUsersWithIDs:(NSArray *)ids forceDownload:(BOOL)forceDownload;
{
    __weak __typeof(self)weakSelf = self;
    return [[self loadFromCache] continueWithBlock:^id(BFTask *task) {
        __typeof(self) strongSelf = weakSelf;
        if (ids.count == 0) {
            return [BFTask taskWithResult:@[]];
        }
        
        if (!forceDownload) {
            // if all users with given ids in cache, return them
            if ([[strongSelf.usersMemoryStorage usersWithIDs:ids] count] == [ids count]) {
                return [BFTask taskWithResult:[strongSelf.usersMemoryStorage usersWithIDs:ids]];
            }
        }
        
        NSSet *usersIDs = [NSSet setWithArray:ids];
        
        QBGeneralResponsePage *pageResponse =
        [QBGeneralResponsePage responsePageWithCurrentPage:1 perPage:usersIDs.count < 100 ? usersIDs.count : 100];
        
        BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
        
        [QBRequest usersWithIDs:usersIDs.allObjects page:pageResponse successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray * users) {
            [strongSelf.usersMemoryStorage addUsers:users];
            
            if ([strongSelf.multicastDelegate respondsToSelector:@selector(usersService:didAddUsers:)]) {
                [strongSelf.multicastDelegate usersService:self didAddUsers:users];
            }
            
            [source setResult:users];
        } errorBlock:^(QBResponse *response) {
            [source setError:response.error.error];
        }];
        
        return source.task;
    }];
}


- (BFTask<NSArray<QBUUser *> *> *)retrieveUsersWithEmails:(NSArray *)emails
{
    __weak __typeof(self)weakSelf = self;
    return [[self loadFromCache] continueWithBlock:^id(BFTask *task) {
        BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
    
        [QBRequest usersWithEmails:emails successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray *users) {
            __typeof(self) strongSelf = weakSelf;
            
            [strongSelf.usersMemoryStorage addUsers:users];
            
            if ([strongSelf.multicastDelegate respondsToSelector:@selector(usersService:didAddUsers:)]) {
                [strongSelf.multicastDelegate usersService:weakSelf didAddUsers:users];
            }
            
            [source setResult:users];
        } errorBlock:^(QBResponse *response) {
            [source setError:response.error.error];
        }];
        
        return source.task;
    }];
}

- (BFTask<NSArray<QBUUser *> *> *)retrieveUsersWithFullName:(NSString *)searchText pagedRequest:(QBGeneralResponsePage *)page cancellationToken:(QMCancellationToken *)token
{
    __weak __typeof(self)weakSelf = self;
#warning Check cancellation token functions
    return [[self loadFromCache] continueWithBlock:^id(BFTask *task) {
        BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
        
        [QBRequest usersWithFullName:searchText page:page successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray *users) {
            __typeof(self) strongSelf = weakSelf;
            
            if (token.isCancelled) {
                [source cancel];
                return;
            }
            
            [strongSelf.usersMemoryStorage addUsers:users];
            
            if ([strongSelf.multicastDelegate respondsToSelector:@selector(usersService:didAddUsers:)]) {
                [strongSelf.multicastDelegate usersService:weakSelf didAddUsers:users];
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
    __weak __typeof(self)weakSelf = self;
    return [[self loadFromCache] continueWithBlock:^id(BFTask *task) {
        __typeof(self) strongSelf = weakSelf;
        BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
        
        QBGeneralResponsePage *pageResponse =
        [QBGeneralResponsePage responsePageWithCurrentPage:1 perPage:facebookIDs.count < 100 ? facebookIDs.count : 100];
    
        [QBRequest usersWithFacebookIDs:facebookIDs page:pageResponse successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray *users) {
            
            [strongSelf.usersMemoryStorage addUsers:users];
            
            if ([strongSelf.multicastDelegate respondsToSelector:@selector(usersService:didAddUsers:)]) {
                [strongSelf.multicastDelegate usersService:strongSelf didAddUsers:users];
            }
            
            [source setResult:users];
        } errorBlock:^(QBResponse *response) {
            [source setError:response.error.error];
        }];
        return source.task;
    }];
}

@end
