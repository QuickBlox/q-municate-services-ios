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
            withCompletionBlock:(QMMediaRestCompletionBlock)completionBlock
                  progressBlock:(QMMediaProgressBlock)progressBlock;

- (BFTask<NSData *> *)downloadMediaItemWithID:(NSString *)mediaID
                                progressBlock:(QMMediaProgressBlock)progressBlock;
@end




