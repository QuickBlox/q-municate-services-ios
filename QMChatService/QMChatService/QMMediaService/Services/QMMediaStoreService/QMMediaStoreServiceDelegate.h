//
//  QMMediaStoreServiceDelegate.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/7/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>


@class QBChatAttachment;
@class QMMediaStoreService;

NS_ASSUME_NONNULL_BEGIN

@protocol QMMediaStoreServiceDelegate <NSObject>

@required

- (void)storeService:(QMMediaStoreService *)storeService
didUpdateAttachment:(QBChatAttachment *)attachment
         messageID:(NSString *)messageID
          dialogID:(NSString *)dialogID;

- (void)storeService:(QMMediaStoreService *)storeService
didRemoveAttachment:(QBChatAttachment *)attachment
         messageID:(NSString *)messageID
          dialogID:(NSString *)dialogID;

@end

NS_ASSUME_NONNULL_END
