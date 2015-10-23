//
//  QMUsersCache.m
//  QMUsersCache
//
//  Created by Andrey Moskvin on 10/23/15.
//  Copyright © 2015 Quickblox. All rights reserved.
//

#import "QMUsersCache.h"
#import "QMUsersModelIncludes.h"

@implementation QMUsersCache

static QMUsersCache *_usersCacheInstance = nil;

#pragma mark - Singleton

+ (QMUsersCache *)instance
{
    NSAssert(_usersCacheInstance, @"You must first perform @selector(setupDBWithStoreNamed:)");
    return _usersCacheInstance;
}

#pragma mark - Configure store

+ (void)setupDBWithStoreNamed:(NSString *)storeName
{
    NSManagedObjectModel *model =
    [NSManagedObjectModel QM_newModelNamed:@"QMUsersModel.momd"
                             inBundleNamed:@"QMUsersCacheModel.bundle"];
    _usersCacheInstance = [[QMUsersCache alloc] initWithStoreNamed:storeName
                                                             model:model queueLabel:"com.qmservicess.QMUsersCacheQueue"];
}

+ (void)cleanDBWithStoreName:(NSString *)name
{
    if (_usersCacheInstance) {
        _usersCacheInstance = nil;
    }
    [super cleanDBWithStoreName:name];
}

#pragma mark - Users



@end
