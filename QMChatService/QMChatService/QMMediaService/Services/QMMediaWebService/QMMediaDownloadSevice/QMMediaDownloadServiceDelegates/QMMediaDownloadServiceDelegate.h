//
//  QMMediaDownloadServiceDelegate.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/7/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "QMMediaBlocks.h"

@protocol QMMediaDownloadDelegate;

@protocol QMMediaDownloadServiceDelegate <NSObject>

- (void)downloadMediaItemWithID:(NSString *)mediaID
                       delegate:(id <QMMediaDownloadDelegate>)delegate;

- (void)downloadMediaItemWithID:(NSString *)mediaID
            withCompletionBlock:(QMMediaRestCompletionBlock)completionBlock
                  progressBlock:(QMMediaProgressBlock)progressBlock;

- (void)addListenerToMediaItemWithID:(NSString *)mediaID
                 withCompletionBlock:(QMMediaRestCompletionBlock)completionBlock
                       progressBlock:(QMMediaProgressBlock)progressBlock;

- (void)addListenerToMediaItemWithID:(NSString *)mediaID
                            delegate:(id <QMMediaDownloadDelegate>)delegate;


@end




