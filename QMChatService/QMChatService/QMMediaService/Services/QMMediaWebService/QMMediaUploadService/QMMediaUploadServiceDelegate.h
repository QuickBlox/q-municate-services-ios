//
//  QMMediaUploadServiceDelegate.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/9/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>

#import "QMMediaBlocks.h"

@protocol QMMediaUploadDelegate;

@protocol QMMediaUploadServiceDelegate <NSObject>

- (void)uploadMediaWithData:(NSData *)data
                   mimeType:(NSString *)mimeType
        withCompletionBlock:(QMMediaUploadCompletionBlock)completionBlock
              progressBlock:(QMMediaProgressBlock)progressBlock;

- (BFTask <QBCBlob *> *)uploadMediaWithData:(NSData *)data
                                   mimeType:(NSString *)mimeType
                              progressBlock:(QMMediaProgressBlock)progressBlock;
@end
