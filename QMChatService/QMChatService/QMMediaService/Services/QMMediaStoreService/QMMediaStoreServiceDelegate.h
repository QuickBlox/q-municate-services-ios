//
//  QMMediaStoreServiceDelegate.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/7/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QMMediaItem;

@class  QBChatAttachment;

@protocol QMMediaStoreServiceDelegate <NSObject>

- (void)updateAttachment:(QBChatAttachment *)attachment;

- (void)localImageForAttachment:(QBChatAttachment *)item
                     completion:(void(^)(UIImage *image))completion;

- (void)save:(QBChatAttachment *)attachment;

- (BOOL)isSavedLocally:(QBChatAttachment *)attachment;

@end
